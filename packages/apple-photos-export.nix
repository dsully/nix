{pkgs, ...}:
if pkgs.stdenv.hostPlatform.isDarwin
then
  with pkgs;
    rustPlatform.buildRustPackage rec {
      pname = "apple-photos-export";
      version = "d47c6c8e";

      src = fetchFromGitHub {
        owner = "haukesomm";
        repo = "apple-photos-export";
        rev = "d47c6c8e18e657ba083df26512849ebdde8fc380";
        hash = "sha256-8YIilPgSP7XABqkBR+mUl+URGzj1RvaT9o7dxd1IJ+E=";
      };

      cargoHash = "sha256-RGiBiON/ODN4yQIZchZUlCYm1WYH7CUo12qO3nz7ryA=";
      doCheck = false;

      nativeBuildInputs = [
        pkg-config
      ];

      buildInputs = [
        sqlite
      ];

      meta = {
        description = "Command line tool to export photos from the macOS Photos library, organized by album and/or date";
        homepage = "https://github.com/haukesomm/apple-photos-export";
        changelog = "https://github.com/haukesomm/apple-photos-export/blob/${src.rev}/CHANGELOG.md";
        license = lib.licenses.mit;
        mainProgram = pname;
        platforms = lib.platforms.darwin;
      };
    }
else pkgs.emptyFile
