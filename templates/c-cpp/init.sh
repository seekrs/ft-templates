text_input "Give a small prefix for project headers or namespace (e.g. ft):" resp
PROJECT_PREFIX=$resp

options=( "Automatic sources generation" "Mandatory/Common/Bonus sources split" "Nix development shell" "ftproject.toml" )
checkbox_input "Select which features you want to use:" options resp

TEMPLATE_DIR=standard
opts_has resp "Mandatory/Common/Bonus sources split" >/dev/null && TEMPLATE_DIR=bonus-split
GENSOURCES=$(opts_has resp "Automatic sources generation")
FTPROJECT_TOML=$(opts_has resp "ftproject.toml")
NIX_SHELL=$(opts_has resp "Nix development shell")

debug "TEMPLATE_DIR=$TEMPLATE_DIR"
debug "GENSOURCES=$GENSOURCES"
debug "FTPROJECT_TOML=$FTPROJECT_TOML"
debug "NIX_SHELL=$NIX_SHELL"

if [ $FTPROJECT_TOML -eq 1 ]; then
	require_fzf
	require_jq

	#TODO: dump projects to json, load w/ jq, pipe into fzf
	text_input "What's the 42 project id?" resp
	PROJECT_ID=$resp
fi

cd $TEMPLATE_DIR
template_install
cd $FTT_PWD

[ $GENSOURCES -eq 0 ] && rm -rf gensources.sh
[ $NIX_SHELL -eq 0 ] && rm -rf shell.nix .envrc flake.nix

#TODO: ft-cli integration w/ login, team-id?
[ $FTPROJECT_TOML -eq 1 ] && cat > ftproject.toml <<-EOF
	[project]
	id = "$PROJECT_ID"
EOF
