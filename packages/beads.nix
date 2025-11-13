{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "0cba73bfc6d72d1975e1cc44a0ccc2563e320251";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-E+K2G16yWNclZJ0LfYkrZe+ETdW2to3RzkP3F5fHPBQ=";
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
