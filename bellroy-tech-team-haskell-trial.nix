{ mkDerivation, base, lib, scotty, sqlite-simple }:
mkDerivation {
  pname = "bellroy-tech-team-haskell-trial";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [ base scotty sqlite-simple ];
  description = "Small project to help Bellroy evaluate Haskell developers";
  license = "unknown";
  hydraPlatforms = lib.platforms.none;
}
