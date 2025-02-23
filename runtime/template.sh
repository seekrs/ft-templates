#!/usr/bin/env false

# Utility functions for template files

function template_install_file() {
	local file=$1
	local dest=$FTT_PWD/$file
	cat $file | mo > "$dest"
	debug "Installed $file to $dest"
}

function template_install() {
	debug "Installing template $(pwd)"

	local variables=$*
	echo "Generating template with $variables"

	if [ -z "$FTT_PWD" ]; then
		echo "!> FTT_PWD is not set"
		leave 1
	fi

	for file in $(\ls -A1 --hide='*.sh'); do
		if [ -f $file ]; then
			template_install_file $file
		else
			pushd $file >/dev/null
			local orig=$FTT_PWD
			FTT_PWD=$FTT_PWD/$file
			mkdir -p $FTT_PWD
			template_install
			FTT_PWD=$orig
			popd >/dev/null
		fi
	done
}

function template_variant_picker() {
	variants=($(\ls -1 --hide='*.sh'))
	list_input "Pick a variant:" variants resp

	if [ ! -d $resp ]; then
		echo "Invalid variant"
		return "INVALID"
	fi

	return $resp
}
