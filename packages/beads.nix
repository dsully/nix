{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "08d8353619777dfdd4119477ca029689597cec60";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-PCsU2GwrPYFAE2KTCdk60E6ZTPRtgNdbPF+bzf8qi3Q=";
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
