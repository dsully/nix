{pkgs, ...}:
with pkgs;
  if pkgs.stdenv.isDarwin
  then
    rustPlatform.buildRustPackage {
      pname = "sps";
      version = "0.1.56";

      src = fetchFromGitHub {
        owner = "alexykn";
        repo = "sps";
        rev = "7afbc6ccce0da39b7cf7ff6f9aa472df1257cc01";
        hash = "sha256-bmcr26uZDEpaifG0sTA+mpsDxAsW9DhT7TcoRwBdip0=";
      };

      cargoHash = "sha256-AD++cxM3nVuzzJxljgzEhcKZba2Z2ggBuRFCA5hefzg=";
      useFetchCargoVendor = true;
      doCheck = false;

      nativeBuildInputs = [
        pkgs.pkg-config
      ];

      buildInputs = [
        pkgs.openssl
      ];

      meta = {
        description = "Rust based package manager for macOS";
        homepage = "https://github.com/alexykn/sps";
        license = lib.licenses.bsd3;
        mainProgram = "sps";
        platforms = lib.platforms.darwin;
      };
    }
  else pkgs.emptyFile
