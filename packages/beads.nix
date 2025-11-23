{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "12f839369c810c1fd2dc5e04c2e496ca0ff95b4f";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-BuOFBAN2y1OcWsoiJN5NlAdNpMZgDePt7vZpVTxYqtM=";
    };

    vendorHash = "sha256-oXPlcLVLoB3odBZzvS5FN8uL2Z9h8UMIbBKs/vZq03I=";
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
