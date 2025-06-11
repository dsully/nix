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
        rev = "6bb507dfd56d01732b05c4c4b7ec70bfffe78ae9";
        hash = "sha256-AaSrqrNFjpftH9MHRiezWO2EhYJqFygJGhVvuIXxgHA=";
      };

      cargoHash = "sha256-43Uh6JBlQMDTwb2BCkdlBlgYiFwQP4kxNuw5OJYVJdo=";
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
