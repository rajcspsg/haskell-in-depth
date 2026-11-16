{ mkDerivation, base, blaze-colonnade, blaze-html, bytestring
, Cabal, cassava, Chart, Chart-diagrams, colonnade, fmt, lib
, optparse-applicative, text, time
}:
mkDerivation {
  pname = "stockquotes";
  version = "0.5";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  enableSeparateDataOutput = true;
  setupHaskellDepends = [ base Cabal ];
  executableHaskellDepends = [
    base blaze-colonnade blaze-html bytestring cassava Chart
    Chart-diagrams colonnade fmt optparse-applicative text time
  ];
  homepage = "https://github.com/bravit/hid-examples#readme";
  description = "Examples to accompany the book \"Haskell in Depth\"";
  license = lib.meta.getLicenseFromSpdxId "BSD-3-Clause";
  mainProgram = "stockquotes";
}
