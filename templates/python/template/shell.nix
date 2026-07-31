{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    (python314.withPackages (p: with p; [
      setuptools
      wheel
      virtualenv
      uv
    ]))
  ];
}
