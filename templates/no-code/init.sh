options=( "Add README & License" )

#TODO: maybe not check? unsure
if command -v nix >/dev/null 2>&1; then
	options+=( "Nix development shell" )
fi

# ft-cli check
if command -v ft >/dev/null 2>&1; then
	options+=( "ftproject.toml" )
fi

checkbox_input "Select which features you want to use:" options resp

README_LICENSE=$(opts_has resp "Add README & License")
FTPROJECT_TOML="$(opts_has resp "ftproject.toml")"
NIX_SHELL="$(opts_has resp "Nix development shell")"

debug "README_LICENSE=$README_LICENSE"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

[[ $README_LICENSE -eq 1 ]] && ask_login FTLOGIN
debug "FTLOGIN=$FTLOGIN"

YEAR=$(date +%Y)
export PROJECT_ID=

if [ $FTPROJECT_TOML -eq 1 ] || [ $README_LICENSE -eq 1 ]; then
	require_fzf
	require_jq

	JSON_FILE=$RUNTIME_DIR/runtime/data/projects.json
	#TODO: try and fetch json into cache first
	#[ ! -f $JSON_FILE && require_ft_cli ] && mkdir -p $(dirname $JSON_FILE) && ft projects --all --json > $RUNTIME_DIR/runtime/data/projects.json

	if [ ! -f $JSON_FILE ]; then
		if [ $FTPROJECT_TOML -eq 1 ]; then
			warn "Could not find 42 projects.json, cannot generate ftproject.toml"
    elif [ $README_LICENSE -eq 1 ]; then
			warn "Could not find 42 projects.json, cannot generate README.md"
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

# Check if the current system already has nix with flakes enabled, otherwise it's not worth it to have a flake
if [ $NIX_SHELL -eq 1 ]; then 
	if [ $FTT_USES_GIT -eq 1 ]; then
		if ! nix flake 2>&1 | grep extra-experimental-features >/dev/null; then
			warn "Locking nix flake, this could take a bit"
			nix flake lock
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
