{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "14f897984ce9fc00677a1481e14615ce0f3f47bd";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-db1jpqwLNcQ/WDJQcUHhaQEnjxxgCOjsKzmpYLDxP9c=";
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
