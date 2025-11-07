{pkgs, ...}:
if pkgs.stdenv.hostPlatform.isDarwin
then
  with pkgs;
    rustPlatform.buildRustPackage rec {
      pname = "apple-photos-export";
      version = "1.1.0-snapshot";

      src = fetchFromGitHub {
        owner = "haukesomm";
        repo = "apple-photos-export";
        rev = "786bf6a1d6a870d81cb710cc7eafbe1c1bbe3be9";
        hash = "sha256-H79YWs1M2aHrdgocvCOHhFcRjQ/ms4YLk2GiLr7f04Y=";
      };

      cargoHash = "sha256-omnfofmWqrU4E/szNJ6s52t0R3bl9/ZR2UNrp49qqdY=";
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
