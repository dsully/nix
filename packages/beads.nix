{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "2f83815ddddb96bfbf5ed9c7aa27cb924a73b85c";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-5IeEBR/CqKCNPhhoYMaGm62VQw2e4cAwi4+wGW78dck=";
    };

    vendorHash = "sha256-jpaeKw5dbZuhV9Z18aQ9tDMS/Eo7HaXiZefm26UlPyI=";
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
