#!/usr/bin/env false

# Utility functions for template files

function template_install_file() {
	local file=$1
	local dest=$FTT_PWD/$file
	install -m 644 $file $dest
	log "Installed $file to $dest"
}

function template_install() {
	debug "Installing template $(pwd)"

	local variables=$*
	echo "Generating template with $variables"

	if [ -z "$FTT_PWD" ]; then
		echo "!> FTT_PWD is not set"
		leave 1
	fi

	for file in $(\ls -1 --hide='*.sh'); do
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

function generate_nix_files() {
	echo "use flake" > .envrc
	cat > flake.nix <<-EOF
		{
		  description = "$PROJECT_NAME";

		  inputs = {
			nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
			systems.url = "github:nix-systems/x86_64-linux";
		  };

		  outputs =
			{ self, nixpkgs, ... }@inputs:
			let
			  inherit (self) outputs;
			  systems = (import inputs.systems);
			  forAllSystems = nixpkgs.lib.genAttrs systems;
			in
			{
			  devShells = forAllSystems (
				system:
				{
				  default = (import ./shell.nix) {
					pkgs = import nixpkgs { inherit system; };
				  };
				}
			  );
			};
		}
	EOF

	cat > shell.nix <<-EOF
		{ pkgs ? import <nixpkgs> {} }:
		let
		  stdenv = pkgs.llvmPackages_20.stdenv;
		in
		(pkgs.mkShell.override { inherit stdenv; }) {
		  nativeBuildInputs = with pkgs; [
			nasm
			valgrind
			gdb
		  ];
		}
	EOF
}
