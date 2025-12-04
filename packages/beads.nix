{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "f4b8a7ad4f7eb3bd47b24357f69f22bc1a75d4b7";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-GmK2+kcaorEsQ/O9lweJIVBv21Np6VfW6sE/3F/GBjY=";
    };

    vendorHash = "sha256-iTPi8+pbKr2Q352hzvIOGL2EneF9agrDmBwTLMUjDBE=";
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
