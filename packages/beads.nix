{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "deaa463d2917a18d5d60985c05f2773b4e0f8147";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-72/7s5Ipyc0tVb5c6bq/EEGlXYVDTD0z54s+Vu83DRM=";
    };

    vendorHash = "sha256-eUwVXAe9d/e3OWEav61W8lI0bf/IIQYUol8QUiQiBbo=";
    doCheck = false;

    ldflags = [
      "-s"
      "-w"
      "-X=main.Version=${version}"
      "-X=main.Build=${src.rev}"
    ];

    meta = {
      description = "Beads - A memory upgrade for your coding agent";
      homepage = "https://github.com/steveyegge/beads";
      changelog = "https://github.com/steveyegge/beads/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "bd";
    };
  }
