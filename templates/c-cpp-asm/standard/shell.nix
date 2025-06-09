{ pkgs ? import <nixpkgs> {} }:
let
  stdenv = pkgs.llvmPackages_20.stdenv;
in
(pkgs.mkShell.override { inherit stdenv; }) {
  nativeBuildInputs = with pkgs; [
    nasm
    valgrind
    gdb
{{#CLANGD_SUPPORT}}
    
    # clangd & compile_commands.json support
    clang-tools
    bear
{{/CLANGD_SUPPORT}}
{{#USE_MACROLIBX}}

    # MacroLibX libraries
    SDL2
    xorg.libX11
{{/USE_MACROLIBX}}
  ];
}
