text_input "Give a small prefix for project headers or namespace (e.g. ft):" resp
PROJECT_PREFIX=$resp

options=( "Add README & License" "Use libft" "Use MacroLibX" "Automatic sources generation" "Nix development shell" "ftproject.toml" )
checkbox_input "Select which features you want to use:" options resp

README_LICENSE=$(opts_has resp "Add README & License")
USE_LIBFT=$(opts_has resp "Use libft")
USE_MACROLIBX=$(opts_has resp "Use MacroLibX")
TEMPLATE_DIR=standard
# [[ $(opts_has resp "Mandatory/Common/Bonus sources split" >/dev/null) == "1" ]] && TEMPLATE_DIR=bonus-split
GENSOURCES=$(opts_has resp "Automatic sources generation")
FTPROJECT_TOML="$(opts_has resp "ftproject.toml")"
NIX_SHELL="$(opts_has resp "Nix development shell")"

debug "README_LICENSE=$README_LICENSE"
debug "USE_LIBFT=$USE_LIBFT"
debug "USE_MACROLIBX=$USE_MACROLIBX"
debug "TEMPLATE_DIR=$TEMPLATE_DIR"
debug "GENSOURCES=$GENSOURCES"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

LIBRARIES=()
[ $USE_LIBFT -eq 1 ] && LIBRARIES+=("libft") && ask_libft_url libft_URL && libft_LIB=libft.a && log "Added libft"
[ "x$(id -nu)" == "xkiroussa" ] && libft_LIB=build/output/libft.a
[ $USE_MACROLIBX -eq 1 ] && LIBRARIES+=("MacroLibX") && MacroLibX_URL=${MACROLIBX_URL:-"https://github.com/seekrs/MacroLibX.git"} && MacroLibX_LIB=libmlx.so && log "Added MLX"
debug "LIBRARIES=$LIBRARIES"
for lib in ${LIBRARIES[@]}; do
	debug "lib='$lib'"
done

[ $USE_LIBFT -eq 1 ] || unset USE_LIBFT
[ $USE_MACROLIBX -eq 1 ] || unset USE_MACROLIBX

debug "LIBRARIES=$LIBRARIES"
debug "LIBFT_URL=$libft_URL"
debug "MacroLibX_URL=$MacroLibX_URL"

ask_login FTLOGIN
debug "FTLOGIN=$FTLOGIN"

YEAR=$(date +%Y)

if [ $FTPROJECT_TOML -eq 1 ] || [ $README_LICENSE -eq 1 ]; then
	require_fzf
	require_jq

	JSON_FILE=$RUNTIME_DIR/runtime/data/projects.json
	#TODO: try and fetch json into cache first
	#[ ! -f $JSON_FILE && require_ft_cli ] && mkdir -p $(dirname $JSON_FILE) && ft projects --all --json > $RUNTIME_DIR/runtime/data/projects.json

	if [ ! -f $JSON_FILE ]; then
		if [ $FTPROJECT_TOML -eq 1 ]; then
			warn "Could not find 42 projects.json, cannot generate ftproject.toml"
		fi
		FTPROJECT_TOML=0
	else
		export PROJECT_ID=$(jq '.[][0]' $JSON_FILE | xargs -I{} echo {} | fzf --prompt="Choose a 42 project id: " --height=12--query "$PROJECT_NAME")
		debug "PROJECT_ID=$PROJECT_ID"
	fi
fi

cd $TEMPLATE_DIR
template_install
cd $FTT_PWD

[ $GENSOURCES -eq 1 ] && bash gensources.sh || rm -rf gensources.sh
[ $NIX_SHELL -eq 1 ] || rm -rf {shell,flake}.nix .envrc
[ $FTPROJECT_TOML -eq 1 ] && write_ftproject 
[ $README_LICENSE -eq 1 ] || rm -rf LICENSE README.md

initialize_git
for lib in ${LIBRARIES[@]}; do add_library $lib; done
if [ $FTT_USES_GIT -eq 1 ]; then
	git submodule update --init --recursive
	if command -v qit >/dev/null 2>&1; then
		qit commit deps "init dependencies"
	else
		git commit -m "Init dependencies"
	fi
fi

