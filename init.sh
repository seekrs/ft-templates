#!/usr/bin/env bash

set -eo pipefail

FTT_NAME="ft-templates"
FTT_VERSION="0.0.1-indev"
if [ command -v git >/dev/null 2>&1 ]; then
	FTT_VERSION="$FTT_VERSION+$(git describe --tags --always --dirty)"
fi
FTT_REPO="seekrs/ft-templates"
FTT_REPO_URL="https://github.com/$FTT_REPO"
FTT_BRANCH="main"
DEBUG=${DEBUG:-0}

function debug() {
	if [ $DEBUG -eq 1 ]; then
		echo "?> $1"
	fi
}

### Dependency management

# Determine the absolute path of the current script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

RUNTIME_DIR=$DIR
IMPORTS=( "common.sh" "inquirer.sh" )
function check_imports() {
	local dir=$1
	for import in "${IMPORTS[@]}"; do
		debug "Checking $dir/$import"
		if [ ! -f $dir/$import ]; then
			debug "Missing $dir/$import"
			# Missing runtime dependency, we need to import it
			return 1
		fi
	done
	debug "All dependencies are present"
	return 0
}

# If runtime dependencies are missing, import them in a temporary directory
if ! check_imports $RUNTIME_DIR/runtime; then
	debug "Missing runtime dependencies at $RUNTIME_DIR"
	TMP=${TMP:-${TMPDIR:-/tmp}}
	RUNTIME_DIR=$TMP/ft-templates_runtime
	mkdir -p $RUNTIME_DIR

	if ! check_imports $RUNTIME_DIR/runtime; then
		debug "Missing runtime dependencies at $RUNTIME_DIR, downloading them"
		mkdir -p $RUNTIME_DIR
		if ! command -v git >/dev/null 2>&1; then
			echo "!> git is required to download runtime dependencies"
			exit 1
		fi
		git clone $FTT_REPO_URL $RUNTIME_DIR
		git -C $RUNTIME_DIR checkout $FTT_BRANCH
	else
		debug "Checking for updates"
		git -C $RUNTIME_DIR pull
	fi
fi

# Ensure common scripts are available
for import in "${IMPORTS[@]}"; do
	debug "Importing $RUNTIME_DIR/runtime/$import"
	source $RUNTIME_DIR/runtime/$import
done
debug "Done importing dependencies"

### Actual script

echo
log "Welcome to $FTT_NAME $FTT_VERSION"
echo

FTT_FULL_LIST=${FTT_FULL_LIST:-0}
# if [ $FTT_FULL_LIST -eq 1 ]; then
# 	log "Showing all templates because FTT_FULL_LIST is set to 1"
# else
# 	log "By default, only the most common templates will be shown."
# 	log "This should be enough for most users, and is the recommended default."
#
# 	choices=( "No" "Yes" )
# 	list_input "Do you want to show the full template list?" choices resp
#
# 	if [ "$resp" = "Yes" ]; then
# 		FTT_FULL_LIST=1
# 	fi
# fi

FTT_PWD=$(pwd)
cd $RUNTIME_DIR/templates
source init.sh
