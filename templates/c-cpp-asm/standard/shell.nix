{ pkgs ? import <nixpkgs> {} }:
let
  stdenv = pkgs.llvmPackages_20.stdenv;
in
(pkgs.mkShell.override { inherit stdenv; }) {
  nativeBuildInputs = with pkgs; [
    nasm
    valgrind
    gdb
{{#USE_MACROLIBX}}
    SDL2
    xorg.libX11
{{/USE_MACROLIBX}}
  ];
}
