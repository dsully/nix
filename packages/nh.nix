{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "108a0cf91a3b66c3a4dfe625877063edf3a1fd84";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-tkFe785sm/O4/fhRoYUp9Qr3wglOhdZOylM4c+CXxUk=";
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
