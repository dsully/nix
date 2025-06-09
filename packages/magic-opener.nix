{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "magic-opener";
    version = "0.0.5";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "magic-opener";
      rev = "01fcf717b7cf67d45a7d37b4e4ad54bc20ee610f";
      hash = "sha256-PFD6gOQAxgwN3HfjjUNDoyCK1Ttjiva0W398qV5Ov2g=";
    };

    cargoHash = "sha256-cBLW7vy87KFJk3Lmd2K+Oj85mHvb2kRM506OextIU98=";
    useFetchCargoVendor = true;

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
