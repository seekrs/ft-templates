text_input "Give a small prefix for project headers or namespace (e.g. ft):" resp
PROJECT_PREFIX=$resp

options=( "Use libft" "Use MacroLibX" "Automatic sources generation" "Mandatory/Common/Bonus sources split" "Nix development shell" "ftproject.toml" )
checkbox_input "Select which features you want to use:" options resp

USE_LIBFT=$(opts_has resp "Use libft")
USE_MACROLIBX=$(opts_has resp "Use MacroLibX")
TEMPLATE_DIR=standard
[[ $(opts_has resp "Mandatory/Common/Bonus sources split" >/dev/null) == "1" ]] && TEMPLATE_DIR=bonus-split
GENSOURCES=$(opts_has resp "Automatic sources generation")
FTPROJECT_TOML="$(opts_has resp "ftproject.toml")"
NIX_SHELL="$(opts_has resp "Nix development shell")"

debug "USE_LIBFT=$USE_LIBFT"
debug "TEMPLATE_DIR=$TEMPLATE_DIR"
debug "GENSOURCES=$GENSOURCES"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

LIBRARIES=""
[ $USE_LIBFT -eq 1 ] && LIBRARIES+="libft " && ask_libft_url libft_URL && libft_LIB=libft.a
[ $USE_MACROLIBX -eq 1 ] && LIBRARIES+="MacroLibX " && MacroLibX_URL=${MACROLIBX_URL:-"https://github.com/seekrs/MacroLibX.git"} && MacroLibX_LIB=libmlx.so
LIBRARIES=( $LIBRARIES )
for lib in $LIBRARIES; do
	debug "lib='$lib'"
done

debug "LIBRARIES=$LIBRARIES"
debug "LIBFT_URL=$libft_URL"
debug "MacroLibX_URL=$MacroLibX_URL"

if [ $FTPROJECT_TOML -eq 1 ]; then
	require_fzf
	require_jq

	#TODO: json exists???
	jq '.[][0]' $RUNTIME_DIR/runtime/data/projects.json | xargs -I{} echo {} | fzf --prompt="Choose a project: " | read PROJECT_ID || error "Invalid project, aborted"
	debug "PROJECT_ID=$PROJECT_ID"
fi

cd $TEMPLATE_DIR
template_install LIBRARIES GENSOURCES LIBFT_URL MACROLIBX_URL
cd $FTT_PWD

[ $GENSOURCES ] && bash gensources.sh || rm -rf gensources.sh
[ $NIX_SHELL -eq 0 ] && rm -rf {shell,flake}.nix .envrc
[ $FTPROJECT_TOML -eq 1 ] && write_ftproject 

initialize_git
for lib in $LIBRARIES; do add_library $lib; done
[ $FTT_USES_GIT -eq 1 ] && git submodule update --init --recursive
