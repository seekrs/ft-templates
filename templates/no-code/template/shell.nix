{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # Put your nix packages here.
    # Find some at https://search.nixos.org/packages
  ];
}
