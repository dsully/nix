{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "dirstat-rs";
    version = "0.3.8";

    src = fetchFromGitHub {
      owner = "scullionw";
      repo = "dirstat-rs";
      rev = "607c2b797078d71eac8a414fa04b46539f5323d1";
      hash = "sha256-oUeDGNKnPmaEYjbhsNeKeqtn5a/js7U2WzUKcn3MRxM=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-LxUSgIl8r/hWU24CBBBkJXxIodVouxyZb0Dsjic/z0o=";

    meta = with lib; {
      description = "Fast, cross-platform disk usage CLI";
      homepage = "https://github.com/scullionw/dirstat-rs";
      license = licenses.mit;
      platforms = platforms.all;
      maintainers = with maintainers; [lanice];
    };
  }
