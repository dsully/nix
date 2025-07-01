{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.16";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = pname;
      rev = "6c83b31bd7d933ea3d2ee8c2622dddbc190e2ab8";
      hash = "sha256-T6bgGAWvjId5Uk+7gzRqTAQxDL2EpsidIA9BHxk/bYE=";
    };

    cargoHash = "sha256-P4t0aMQVo7962SxgT7tUv6G+rHgO2PbE8bEPAI63rRQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
