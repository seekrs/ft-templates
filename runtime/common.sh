#!/usr/bin/env false

function log() {
	echo "*> $*" 1>&2
}

function warn() {
	echo "!> $*" 1>&2
}

function error() {
	echo "!!!> $*" 1>&2
}

function opts_has() {
	local IFS=$'\n'
	local _options
	eval _options=( '"${'${1}'[@]}"' )
	# debug "options=${_options[@]}"
	local opt=$2
	debug "target=$opt"
	for o in ${_options[@]}; do
		debug "o=$o"
		if [ "$o" = "$opt" ]; then
			debug "Found"
			echo "1"
			return 0
		fi
	done
	debug "Not found"
	echo "0"
	return 1
}

function require_fzf() {
	debug "Checking for fzf"
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
}

function require_jq() {
	debug "Checking for jq"
	if ! command -v jq >/dev/null 2>&1; then
		if [ ! -f $RUNTIME_DIR/bin/jq ]; then
			warn "jq is missing, installing it"
			mkdir -p $RUNTIME_DIR/bin
			curl -sSL https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -o $RUNTIME_DIR/bin/jq
			chmod +x $RUNTIME_DIR/bin/jq
		fi
	fi
}
