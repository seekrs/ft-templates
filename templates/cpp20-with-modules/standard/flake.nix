{
  description = "{{PROJECT_NAME}}";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;

      forAllSystems =
        function:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system: function nixpkgs.legacyPackages.${system}
        );
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt);
      devShells = forAllSystems (pkgs: {
        default =
          let
            llvmPackages = pkgs.llvmPackages_23;
            stdenv = pkgs.stdenvAdapters.useMoldLinker llvmPackages.libcxxStdenv;
          in
          (pkgs.mkShell.override { inherit stdenv; }) {
            hardeningDisable = [ "fortify" ];

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

            LIBCXX_SHARE_PATH = "${llvmPackages.libcxx}/share/libc++/v1";

            shellHook = ''
              unset NIX_ENFORCE_NO_NATIVE
            '';
          };
      });
    };
}
