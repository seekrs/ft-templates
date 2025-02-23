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
