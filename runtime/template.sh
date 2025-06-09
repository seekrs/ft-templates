#!/usr/bin/env false

# Utility functions for template files

function template_install_file() {
	local file=$1
	local dest=$FTT_PWD/$file
  debug "Installing $file to $dest"
	cat $file | mo > "$dest" || warn "Failed to install $file"
	# debug "Installed $file to $dest"
}

function template_install() {
	debug "Installing template $(pwd)"

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

function add_library() {
	local libName=$1
	local libUrlVar=${libName}_URL
	local libUrl
	eval libUrl=\$$libUrlVar
	[ -z "$libUrl" ] && error "No URL for $libName" && return
	mkdir -p third-party

	if [ -d $libName ]; then
		warn "Library $libName already exists, skipping"
		return
	fi

	if [ $FTT_USES_GIT -eq 1 ]; then
		git submodule add $libUrl third-party/$libName
	else
		git clone --recursive $libUrl third-party/$libName
		find third-party/$libName -name ".git" -exec rm -rf {} \; 2>/dev/null || true
	fi
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
