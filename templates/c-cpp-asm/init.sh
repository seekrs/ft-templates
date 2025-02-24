text_input "Give a small prefix for project headers or namespace (e.g. ft):" resp
PROJECT_PREFIX=$resp

options=( "Use libft" "Use MacroLibX" "Automatic sources generation" "Mandatory/Common/Bonus sources split" "Nix development shell" "ftproject.toml" )
checkbox_input "Select which features you want to use:" options resp

USE_LIBFT=$(opts_has resp "Use libft")
USE_MACROLIBX=$(opts_has resp "Use MacroLibX")
TEMPLATE_DIR=standard
# [[ $(opts_has resp "Mandatory/Common/Bonus sources split" >/dev/null) == "1" ]] && TEMPLATE_DIR=bonus-split
GENSOURCES=$(opts_has resp "Automatic sources generation")
FTPROJECT_TOML="$(opts_has resp "ftproject.toml")"
NIX_SHELL="$(opts_has resp "Nix development shell")"

debug "USE_LIBFT=$USE_LIBFT"
debug "USE_MACROLIBX=$USE_MACROLIBX"
debug "TEMPLATE_DIR=$TEMPLATE_DIR"
debug "GENSOURCES=$GENSOURCES"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

LIBRARIES=""
[ $USE_LIBFT ] && LIBRARIES+="libft " && ask_libft_url libft_URL && libft_LIB=libft.a
[ $USE_MACROLIBX ] && LIBRARIES+="MacroLibX " && MacroLibX_URL=${MACROLIBX_URL:-"https://github.com/seekrs/MacroLibX.git"} && MacroLibX_LIB=libmlx.so && log "Added MLX"
LIBRARIES=( $LIBRARIES )
for lib in $LIBRARIES; do
	debug "lib='$lib'"
done

debug "LIBRARIES=$LIBRARIES"
debug "LIBFT_URL=$libft_URL"
debug "MacroLibX_URL=$MacroLibX_URL"

if [ $FTPROJECT_TOML ]; then
	require_fzf
	require_jq

	JSON_FILE=$RUNTIME_DIR/runtime/data/projects.json
	#TODO: try and fetch json into cache first
	#[ ! -f $JSON_FILE && require_ft_cli ] && mkdir -p $(dirname $JSON_FILE) && ft projects --all --json > $RUNTIME_DIR/runtime/data/projects.json

	if [ ! -f $JSON_FILE ]; then
		warn "Could not find 42 projects.json, cannot generate ftproject.toml"
		FTPROJECT_TOML=0
	else
		export PROJECT_ID=$(jq '.[][0]' $JSON_FILE | xargs -I{} echo {} | fzf --prompt="Choose a 42 project id: " --height=12)
		debug "PROJECT_ID=$PROJECT_ID"
	fi
fi

cd $TEMPLATE_DIR
template_install LIBRARIES GENSOURCES
cd $FTT_PWD

[ $GENSOURCES ] && bash gensources.sh || rm -rf gensources.sh
[ $NIX_SHELL ] || rm -rf {shell,flake}.nix .envrc
[ $FTPROJECT_TOML ] && write_ftproject 

initialize_git
for lib in $LIBRARIES; do add_library $lib; done
[ $FTT_USES_GIT ] && git submodule update --init --recursive
