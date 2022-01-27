{
  description = "Bellroy Tech Team Haskell Trial";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem (system:
    let
      nixpkgs = import inputs.nixpkgs { inherit system; };
      package = nixpkgs.haskellPackages.callPackage
        ./bellroy-tech-team-haskell-trial.nix
        { };
    in
    {
      defaultPackage = package;
      devShell = package.env.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [
          nixpkgs.cabal-install nixpkgs.zlib
        ];
      });
    }
  );
}
