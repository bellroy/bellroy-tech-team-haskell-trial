{
  description = "Bellroy Tech Team Haskell Trial";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        nixpkgs = import inputs.nixpkgs { inherit system; };
        package = nixpkgs.haskellPackages.callPackage ./bellroy-tech-team-haskell-trial.nix { };
      in
      {
        defaultPackage = package;
        devShell = package.env.overrideAttrs (oldAttrs: {
          buildInputs = oldAttrs.buildInputs ++ [
            nixpkgs.cabal-install
            nixpkgs.haskellPackages.cabal-fmt
            nixpkgs.zlib
            nixpkgs.ormolu
          ];
        });
      }
    );
}
