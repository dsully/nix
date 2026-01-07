{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "5f279c597e6e2af1757e0cd0b071aeb29d3e85a5";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-8VCfAbKKj+OHD5Mz5TBB7mE/zWe/5MyFTbXEayI0WG8=";
    };

    cargoHash = "sha256-M7Pgy/OsHLiNkwap0axTFm0ym0/3JQwwBNxlobuMZbg=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
