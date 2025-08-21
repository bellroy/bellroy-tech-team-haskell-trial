# Tech Team Haskell Trial

This is a simple [Scotty](https://hackage.haskell.org/package/scotty)
application to help us evaluate potential Haskell developers. It
implements a HTTP API with a single endpoint which returns shipping
rates for a given country.

# Setup

Clone the repo (please don't fork it), and then you can use:

* `cabal build`/`cabal run tech-team-haskell-trial`/`cabal test` directly, provided you have `zlib` and `pkg-config` installed;
* `nix develop`, then `cabal build`/`cabal run`
