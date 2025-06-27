{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "sith-language-server";
    version = "0.2.4-alpha";

    src = fetchFromGitHub {
      owner = "LaBatata101";
      repo = pname;
      rev = "2373054412a0e85ddb9554e40573fef2171b6370";
      hash = "sha256-eQjbKm+4GlPW3sumi1qHypgsOVTcU8Z8Afm4S8MjDUI=";
    };

    cargoHash = "sha256-mtJVR4EKw+e0osmNKlis++6xL7Bo2Xel9wDEmrUn6x4=";
    useFetchCargoVendor = true;
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      zstd
    ];

    env = {
      ZSTD_SYS_USE_PKG_CONFIG = true;
    };

    meta = {
      description = "An experimental Python language server made in Rust";
      homepage = "https://github.com/LaBatata101/sith-language-server";
      license = lib.licenses.mit;
      mainProgram = "sith-lsp";
    };
  }
