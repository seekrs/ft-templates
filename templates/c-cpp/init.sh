text_input "Give a small prefix for project headers or namespace (e.g. ft):" resp
PROJECT_PREFIX=$resp

options=( "Automatic sources generation" "Mandatory/Common/Bonus sources split" "Nix development shell" "ftproject.toml" )
checkbox_input "Select which features you want to use:" options resp

TEMPLATE_DIR=standard
GENSOURCES=0
FTPROJECT_TOML=0
NIX_SHELL=0
for option in "${resp[@]}"; do
	case $option in
		"Automatic sources generation")
			GENSOURCES=1
			;;
		"Mandatory/Common/Bonus sources split")
			TEMPLATE_DIR=bonus-split
			;;
		"Nix development shell")
			NIX_SHELL=1
			;;
		"ftproject.toml")
			FTPROJECT_TOML=1
			;;
	esac
done

if [ $FTPROJECT_TOML -eq 1 ]; then
	if ! command -v fzf >/dev/null 2>&1; then
		if [ ! -f $RUNTIME_DIR/bin/fzf ]; then
			warn "fzf is missing, installing it"
			tmpdir=$(mktemp -d)
			pushd $tmpdir >/dev/null
			curl -sSL https://github.com/junegunn/fzf/releases/download/v0.60.1/fzf-0.60.1-linux_amd64.tar.gz | tar -xz
			mkdir -p $RUNTIME_DIR/bin
			install -m 755 fzf $RUNTIME_DIR/bin/fzf
			popd >/dev/null
			rm -rf $tmpdir
		fi

	fi
	export FZF_DEFAULT_OPTS="--height 100% --reverse --border --prompt='> '"

	if ! command -v jq >/dev/null 2>&1; then
		if [ ! -f $RUNTIME_DIR/bin/jq ]; then
			warn "jq is missing, installing it"
			mkdir -p $RUNTIME_DIR/bin
			curl -sSL https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -o $RUNTIME_DIR/bin/jq
			chmod +x $RUNTIME_DIR/bin/jq
		fi
	fi

	#TODO: dump projects to json, load w/ jq, pipe into fzf
	text_input "What's the 42 project id?" resp
	PROJECT_ID=$resp
fi

cd $TEMPLATE_DIR

template_install

cd $FTT_PWD

if [ $GENSOURCES -eq 0 ]; then
	rm -rf gensources.sh
fi

if [ $NIX_SHELL -eq 0 ]; then
	rm -rf shell.nix .envrc flake.nix
fi

if [ $FTPROJECT_TOML -eq 1 ]; then
	#TODO: ft-cli integration w/ login, team-id?
	cat > ftproject.toml <<-EOF
		[project]
		id = "$PROJECT_ID"
	EOF
fi
