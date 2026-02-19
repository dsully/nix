{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "503409a7c8f4807a84b766df611a0b69e217f977";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-+jWlSuOMEAlCBUJd0sU0i9Uvk0KtMDEigRdQUWcAs9Q=";
    };

    cargoHash = "sha256-JeKTrA9AbAyjZ54rZqN66HexxvNFSWEsaFM4nvVK4c4=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
