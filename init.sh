#!/usr/bin/env bash

set -eo pipefail

FTT_NAME="ft-templates"
FTT_VERSION="0.0.4-indev"
FTT_REPO="seekrs/ft-templates"
FTT_REPO_URL="https://github.com/$FTT_REPO"
FTT_BRANCH="main"
DEBUG=${DEBUG:-0}

# https://stackoverflow.com/a/28776166
sourced=0
if [ -n "$ZSH_VERSION" ]; then 
	case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
	[ "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" != "$(cd -- "$(dirname -- "${.sh.file}")" && pwd -P)/$(basename -- "${.sh.file}")" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
	(return 0 2>/dev/null) && sourced=1 
else # All other shells: examine $0 for known shell binary filenames.
	 # Detects `sh` and `dash`; add additional shell filenames as needed.
	case ${0##*/} in sh|-sh|dash|-dash) sourced=1;; esac
fi

if [ $sourced -eq 1 ]; then
	echo "!!!> This script should not be sourced, run it directly"
	return 1
fi

function debug() {
	if [ $DEBUG -eq 1 ]; then
		echo "?> $*" 1>&2
	fi
}

function leave() {
	debug "Leaving, exit code: $1"

	exit $1
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

IMPORTS=( "common.sh" "inquirer.sh" "template.sh" "mo.sh" )
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
			leave 1
		fi
		git clone $FTT_REPO_URL $RUNTIME_DIR >/dev/null
		if [ $? -ne 0 ]; then
			echo "!> Failed to clone runtime dependencies"
			leave 1
		fi
		git -C $RUNTIME_DIR checkout $FTT_BRANCH >/dev/null
		if [ $? -ne 0 ]; then
			echo "!> Failed to checkout runtime dependencies"
			leave 1
		fi
	else
		debug "Checking for updates"
		git -C $RUNTIME_DIR pull --ff-only >/dev/null
		if [ $? -ne 0 ]; then
			echo "!> Failed to update runtime"
			leave 1
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

if [[ "$FTT_PWD" == "$RUNTIME_DIR" ]]; then
	warn "Looks like you're running this script from the runtime directory, which is not recommended."
	warn "You should specify another directory to use as the project root."
	text_input "New project root:" resp
	mkdir -vp $resp
	echo
	cd $resp
	FTT_PWD=$(pwd)
fi

text_input "What's the name of your project?" resp
PROJECT_NAME=$resp
if [[ "x$PROJECT_NAME" == "x" ]]; then
	error "Invalid project name"
	leave 2
fi

if [ -d $PROJECT_NAME ]; then
	error "Directory with that name already exists"
	leave 2
fi

mkdir -vp $PROJECT_NAME
cd $PROJECT_NAME
FTT_PWD=$(pwd)
debug "PROJECT_NAME=$PROJECT_NAME"

trap "rm -rf $FTT_PWD" EXIT

export PATH="$PATH:$RUNTIME_DIR/bin"

cd $RUNTIME_DIR/templates
# debug "$(pwd) $PWD"
# debug "ls=$(ls)"
source ./init.sh

trap - EXIT

log "All done!"
echo

log "You can run \`cd $FTT_PWD\` to get started!"
