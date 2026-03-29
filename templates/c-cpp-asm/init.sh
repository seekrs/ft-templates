options=( "Add README & License" "Dependency: libft" "Dependency: MacroLibX" "Automatic sources generation" "clangd support" )

#TODO: maybe not check? unsure
if command -v nix >/dev/null 2>&1; then
	options+=( "Nix development shell" )
fi

# ft-cli check
if command -v ft >/dev/null 2>&1; then
	options+=( "ftproject.toml" )
fi

# kiroussa moment
if [[ $(id -nu) == "kiroussa" ]] || [ -f $HOME/.config/ft-templates/hi-im-kroussar ]; then
	options+=( "Dependency: libftstd" )
	options+=( "Dependency: libkroussar" )
fi

# sort options alphabetically
mapfile -t options < <(printf '%s\n' "${options[@]}" | sort)

checkbox_input "Select which features you want to use:" options resp

README_LICENSE=$(opts_has resp "Add README & License")
USE_LIBFT=$(opts_has resp "Dependency: libft")
USE_MACROLIBX=$(opts_has resp "Dependency: MacroLibX")
USE_LIBFTSTD=$(opts_has resp "Dependency: libftstd")
USE_LIBKROUSSAR=$(opts_has resp "Dependency: libkroussar")
CLANGD_SUPPORT=$(opts_has resp "clangd support")
TEMPLATE_DIR=standard
# [[ $(opts_has resp "Mandatory/Common/Bonus sources split" >/dev/null) == "1" ]] && TEMPLATE_DIR=bonus-split
GENSOURCES=$(opts_has resp "Automatic sources generation")
FTPROJECT_TOML="$(opts_has resp "ftproject.toml")"
NIX_SHELL="$(opts_has resp "Nix development shell")"

debug "README_LICENSE=$README_LICENSE"
debug "USE_LIBFT=$USE_LIBFT"
debug "USE_MACROLIBX=$USE_MACROLIBX"
debug "USE_LIBFTSTD=$USE_LIBFTSTD"
debug "USE_LIBKROUSSAR=$USE_LIBKROUSSAR"
debug "TEMPLATE_DIR=$TEMPLATE_DIR"
debug "GENSOURCES=$GENSOURCES"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

LIBRARIES=()
[ $USE_LIBFT -eq 1 ] && LIBRARIES+=("libft") && ask_libft_url libft_URL && libft_LIB=libft.a && log "Added libft"
[ $USE_MACROLIBX -eq 1 ] && LIBRARIES+=("MacroLibX") && MacroLibX_URL=${MACROLIBX_URL:-"https://github.com/seekrs/MacroLibX.git"} && MacroLibX_LIB=libmlx.so && MacroLibX_INCDIR=includes && log "Added MLX"
[ $USE_LIBFTSTD -eq 1 ] && LIBRARIES+=("libftstd") && libftstd_URL=${LIBFTSTD_URL:-"https://codeberg.org/27/libftstd.git"} && libftstd_LIB=libftstd.a libftstd_INCDIR=__ignored && log "Added libftstd"
[ $USE_LIBKROUSSAR -eq 1 ] && LIBRARIES+=("libkroussar") && libkroussar_URL=${LIBKROUSSAR_URL:-"https://codeberg.org/27/libkroussar.git"} && libkroussar_LIB=libkroussar.a && log "Added libkroussar"
debug "LIBRARIES=$LIBRARIES"
for lib in ${LIBRARIES[@]}; do
	# if $lib_INCDIR is not set, set it to "include"
	incdir_var="${lib}_INCDIR"
	if [ -z "${!incdir_var}" ]; then
		export ${incdir_var}=include
	fi
	debug "lib='$lib'"
	debug "lib_INCDIR='${!incdir_var}'"
done

# If we want a variable to be "false" in mustache, we need to unset it
[ $USE_LIBFT -eq 1 ] || unset USE_LIBFT
[ $USE_MACROLIBX -eq 1 ] || unset USE_MACROLIBX
[ $USE_LIBFTSTD -eq 1 ] || unset USE_LIBFTSTD
[ $USE_LIBKROUSSAR -eq 1 ] || unset USE_LIBKROUSSAR
[ $GENSOURCES -eq 1 ] || unset GENSOURCES;
[ $CLANGD_SUPPORT -eq 1 ] || unset CLANGD_SUPPORT

debug "LIBRARIES=$LIBRARIES"
debug "LIBFT_URL=$libft_URL"
debug "MacroLibX_URL=$MacroLibX_URL"

[[ $README_LICENSE -eq 1 ]] && ask_login FTLOGIN
debug "FTLOGIN=$FTLOGIN"

[ "x$(id -nu)" == "xkiroussa" ] && libft_LIB=build/output/libft.a
[ "x$FTLOGIN" == "xkiroussa" ] && libft_LIB=build/output/libft.a

YEAR=$(date +%Y)
export PROJECT_ID=

if [ $FTPROJECT_TOML -eq 1 ] || [ $README_LICENSE -eq 1 ]; then
	require_fzf
	require_jq

	JSON_FILE=$RUNTIME_DIR/runtime/data/projects.json
	#TODO: try and fetch json into cache first
	#[ ! -f $JSON_FILE && require_ft_cli ] && mkdir -p $(dirname $JSON_FILE) && ft projects --all --format=json > $RUNTIME_DIR/runtime/data/projects.json

	if [ ! -f $JSON_FILE ]; then
		if [ $FTPROJECT_TOML -eq 1 ]; then
			warn "Could not find 42 projects.json, cannot generate ftproject.toml"
		fi
		FTPROJECT_TOML=0
	else
		export PROJECT_ID=$(jq '.[][0]' $JSON_FILE | xargs -I{} echo {} | fzf --prompt="Choose a 42 project id: " --height=12 --query "$PROJECT_NAME")
		debug "PROJECT_ID=$PROJECT_ID"
	fi
fi

cd $TEMPLATE_DIR
template_install
cd $FTT_PWD

[ $NIX_SHELL -eq 1 ] || rm -f {shell,flake}.nix .envrc
[ $FTPROJECT_TOML -eq 1 ] && write_ftproject 
[ $README_LICENSE -eq 1 ] || rm -rf LICENSE README.md

initialize_git

#TODO: Move this to a runtime function
# Check if the current system already has nix with flakes enabled, otherwise it's not worth it to have a flake
if [ $NIX_SHELL -eq 1 ]; then 
	if [ $FTT_USES_GIT -eq 1 ]; then
		if ! nix flake 2>&1 | grep extra-experimental-features >/dev/null; then
			warn "Locking nix flake, this could take a bit"
			nix flake lock
			git add .
			if command -v qit >/dev/null 2>&1; then
				qit commit deps -a flake.lock "init lockfile"
			else
				git commit -m "Init flake lockfile"
			fi
		else
			warn "Nix flakes don't seem to be enabled, skipping flake generation"
			rm -f flake.nix
		fi
	else
		warn "Not using a git repository, skipping flake generation"
		rm -f flake.nix
	fi
fi

#TODO: Move this to a runtime function
for lib in ${LIBRARIES[@]}; do add_library $lib; done
if [ $FTT_USES_GIT -eq 1 ]; then
	git submodule update --init --recursive
	if command -v qit >/dev/null 2>&1; then
		qit commit deps "init dependencies"
	else
		git commit -m "Init dependencies"
	fi
fi

