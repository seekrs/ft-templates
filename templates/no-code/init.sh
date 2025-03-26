options=( "Add README & License" "Nix development shell" "ftproject.toml" )
checkbox_input "Select which features you want to use:" options resp

README_LICENSE=$(opts_has resp "Add README & License")
FTPROJECT_TOML="$(opts_has resp "ftproject.toml")"
NIX_SHELL="$(opts_has resp "Nix development shell")"

debug "README_LICENSE=$README_LICENSE"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

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
		export PROJECT_ID=$(jq '.[][0]' $JSON_FILE | xargs -I{} echo {} | fzf --prompt="Choose a 42 project id: " --height=12 --query "$PROJECT_NAME")
		debug "PROJECT_ID=$PROJECT_ID"
	fi
fi

cd template
template_install
cd $FTT_PWD

[ $NIX_SHELL -eq 1 ] || rm -rf {shell,flake}.nix .envrc
[ $FTPROJECT_TOML -eq 1 ] && write_ftproject 
[ $README_LICENSE -eq 1 ] || rm -rf LICENSE README.md

initialize_git
