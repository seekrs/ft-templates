#!/usr/bin/env bash

set -eo pipefail

FTT_NAME="ft-templates"
FTT_VERSION="0.0.1-indev"
if command -v git >/dev/null 2>&1 && [ -d .git ]; then
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
debug "SOURCE=$SOURCE"
# if we're in a /proc/self/fd/N directory, skip all this
if [[ "$SOURCE" =~ ^/proc/self/fd/.* ]]; then
	debug "Skipping dependency management in a procfs directory"
	RUNTIME_DIR=/nonexistent
else
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
		SOURCE="$(readlink "$SOURCE")"
		[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

	RUNTIME_DIR=$DIR
fi

IMPORTS=( "common.sh" "inquirer.sh" )
function check_imports() {
	local dir=$1
	if [ ! -d $dir ]; then
		debug "Missing $dir"
		return 1
	fi
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
		if [ -d $RUNTIME_DIR ]; then
			debug "Removing existing runtime directory"
			rm -rf $RUNTIME_DIR
		fi
		mkdir -p $RUNTIME_DIR
		if ! command -v git >/dev/null 2>&1; then
			echo "!> git is required to download runtime dependencies"
			exit 1
		fi
		git clone $FTT_REPO_URL $RUNTIME_DIR >/dev/null
		if [ $? -ne 0 ]; then
			echo "!> Failed to clone runtime dependencies"
			exit 1
		fi
		git -C $RUNTIME_DIR checkout $FTT_BRANCH >/dev/null
		if [ $? -ne 0 ]; then
			echo "!> Failed to checkout runtime dependencies"
			exit 1
		fi
	else
		debug "Checking for updates"
		git -C $RUNTIME_DIR pull --ff-only >/dev/null
		if [ $? -ne 0 ]; then
			echo "!> Failed to update runtime"
			exit 1
		fi
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

FTT_SHOW_ALL=${FTT_SHOW_ALL:-0}
# if [ $FTT_SHOW_ALL -eq 1 ]; then
# 	log "Showing all templates because FTT_SHOW_ALL is set to 1"
# else
# 	log "By default, only the most common templates will be shown."
# 	log "This should be enough for most users, and is the recommended default."
#
# 	choices=( "No" "Yes" )
# 	list_input "Do you want to show the full template list?" choices resp
#
# 	if [ "$resp" = "Yes" ]; then
# 		FTT_SHOW_ALL=1
# 	fi
# fi

FTT_PWD=$(pwd)
debug "FTT_PWD=$FTT_PWD"
debug "RUNTIME_DIR=$RUNTIME_DIR"
cd $RUNTIME_DIR/templates
debug "$(pwd) $PWD"
debug "ls=$(ls)"
source ./init.sh
