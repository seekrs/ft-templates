{
  pkgs ? import <nixpkgs> {}
}:

let
  stdenv = pkgs.stdenvAdapters.useMoldLinker pkgs.llvmPackages_22.stdenv;
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

    # Put your nix packages here.
    # Find some at https://search.nixos.org/packages
  ];
{{#USE_MACROLIBX}}
  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.vulkan-loader}/lib:$LD_LIBRARY_PATH";
  '';
  buildInputs = with pkgs; [
    # MacroLibX libraries
    SDL2
    libx11.dev
    vulkan-headers
    vulkan-loader
    vulkan-loader.dev
    vulkan-tools
    vulkan-validation-layers
  ];
{{/USE_MACROLIBX}}
}
