{pkgs, ...}:
if pkgs.stdenv.isDarwin
then
  with pkgs;
    rustPlatform.buildRustPackage rec {
      pname = "apple-photos-export";
      version = "ae62de52";

      src = fetchFromGitHub {
        owner = "haukesomm";
        repo = "apple-photos-export";
        rev = "ae62de52731b57b57ab20dd3a9ef361bce78b07f";
        hash = "sha256-6p0NkaGDdIXoEWR1tia7hiPewmnJsFCFLehscO0fQNI=";
      };

      cargoHash = "sha256-1oqtnfqMSYTjCuAF/PNJ6I4LbfxzksGoSVmnCWNcMiQ=";
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
        mainProgram = "apple-photos-export";
        platforms = lib.platforms.darwin;
      };
    }
else pkgs.emptyFile
