
{
  description = "Stock Quotes - Haskell application";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/haskell-updates";

    flake-utils.url = "github:numtide/flake-utils";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, git-hooks }:

    let

      # =====================================================
      # Custom Haskell overlay
      # =====================================================

      stockQuotesOverlay = final: prev:

        let

          # Relax Cabal constraints and clear broken metadata.
          jailbreakUnbreak = pkg:
            prev.haskell.lib.doJailbreak
              (pkg.overrideAttrs (old: {
                meta = (old.meta or {}) // {
                  broken = false;
                };
              }));

          # Relax Cabal constraints and remove stale revisions.
          overrideCabalConstraints = pkg:
            prev.haskell.lib.overrideCabal
              (jailbreakUnbreak pkg)
              (old: {
                editedCabalFile = null;
                revision = null;
              });

          # GHC 9.14.1 Haskell package set.
          hs = prev.haskell.packages.ghc914.override {

            overrides = hself: hsuper: {

              # -------------------------------------------------
              # Diagrams compatibility
              # -------------------------------------------------

              diagrams-core =
                jailbreakUnbreak hsuper.diagrams-core;

              diagrams-lib =
                jailbreakUnbreak hsuper.diagrams-lib;

              diagrams-postscript =
                jailbreakUnbreak hsuper.diagrams-postscript;

              diagrams-svg =
                overrideCabalConstraints hsuper.diagrams-svg;

              svg-builder =
                overrideCabalConstraints hsuper.svg-builder;

              # -------------------------------------------------
              # Other dependencies
              # -------------------------------------------------

              colonnade =
                prev.haskell.lib.dontCheck
                  (jailbreakUnbreak hsuper.colonnade);

              dictionary-sharing =
                jailbreakUnbreak hsuper.dictionary-sharing;

              statestack =
                jailbreakUnbreak hsuper.statestack;

              fmt =
                prev.haskell.lib.dontCheck
                  hsuper.fmt;

              doctest =
                prev.haskell.lib.dontCheck
                  hsuper.doctest;

              tasty-inspection-testing =
                prev.haskell.lib.dontCheck
                  hsuper.tasty-inspection-testing;

              # Relax optparse-applicative constraints.
              optparse-applicative =
                jailbreakUnbreak hsuper.optparse-applicative;
            };
          };

        in
        {
          stockQuotesHaskellPackages = hs;
        };

    in

    {
      # =====================================================
      # Export overlay
      # =====================================================

      overlays.default = stockQuotesOverlay;

    } //

    flake-utils.lib.eachDefaultSystem (system:

      let

        # Import nixpkgs with custom overlay.
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            stockQuotesOverlay
          ];
        };

        # Custom Haskell package set.
        hs = pkgs.stockQuotesHaskellPackages;

        packageName = "stock-quotes";

        # Build application and relax its Cabal constraints.
        stock-quotes-project =
          pkgs.haskell.lib.doJailbreak
            (hs.callCabal2nix packageName ./. {});

      in

      {
        # ===================================================
        # Packages
        # ===================================================

        packages = {
          default = stock-quotes-project;
          ${packageName} = stock-quotes-project;
        };

        # ===================================================
        # Development shell
        # ===================================================

        devShells.default = pkgs.mkShell {

          packages = [
            hs.ghc
            pkgs.cabal-install
            pkgs.zstd
            pkgs.zlib
            pkgs.xz
            pkgs.bzip2
          ];

          LD_LIBRARY_PATH =
            pkgs.lib.makeLibraryPath [
              pkgs.zstd
              pkgs.zlib
              pkgs.xz
              pkgs.bzip2
            ];

          shellHook = ''
            export LANG=C.UTF-8
            export LC_ALL=C.UTF-8

            echo "=================================="
            echo " Stock Quotes Haskell Environment"
            echo "=================================="

            ghc --version
            cabal --version
          '';
        };

      }
    );
}
