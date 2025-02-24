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
			return
		fi
	done
	debug "Not found"
	echo "0"
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
	export FZF_DEFAULT_OPTS="--reverse --border --prompt='> '"
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

function ask_libft_url() {
	local file=$RUNTIME_DIR/libft.local
	if [ -f $file ]; then
		local contents=$(cat $file)
		eval "$1=$contents"
		log "Using cached libft URL: $contents"
		return
	fi

	local libft_url
	text_input "Enter your libft repository URL (HTTPS or SSH):" libft_url 
	log "Saving libft URL to $file for next times"
	echo $libft_url > $file
	eval "$1=$libft_url"
}

#TODO: ft-cli integration w/ login, team-id?
function write_ftproject() {
	cat > ftproject.toml <<-EOF
		[project]
		id = "$PROJECT_ID"
	EOF
}

function initialize_git() {
	yn=( "Yes" "No" )
	list_input "Do you want to create a git repository and commit the changes?" yn resp
	export FTT_USES_GIT=0

	if [[ $resp == "Yes" ]]; then
		export FTT_USES_GIT=1
		if [ ! -d .git ]; then
			git init
		fi
		git add .
		#TODO: ft commit? lol
		if command -v qit >/dev/null 2>&1; then
			qit commit feature "initial commit"
		else
			git commit -m "Initial commit"
		fi
	fi
}
