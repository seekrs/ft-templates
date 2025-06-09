{
  description = "{{PROJECT_NAME}}";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/x86_64-linux";
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;

      systems = (import inputs.systems);
      forAllSystems =
        fn:
        (nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              # config.allowUnfree = true;
            };
          in
          fn system pkgs
        ));
    in
    {
      formatter = forAllSystems (system: pkgs: pkgs.nixfmt-rfc-style);
      devShells = forAllSystems (
        system: pkgs: {
          default = (import ./shell.nix) { inherit pkgs; };
        }
      );
    };
}
