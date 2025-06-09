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
        rev = "7c9de4e2c897944dc23e8b9e03410060e3445af8";
        hash = "sha256-50BpBvD7Ire6KPgvEBqquw00gDxZh9Adjgslb3WDk8M=";
      };

      cargoHash = "sha256-Yn6N9drCaGjY/Z/C0jRxX9H3+BriOZhEO3klSd3EDMs=";
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
  else {}
