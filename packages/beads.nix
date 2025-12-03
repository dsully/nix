{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "8d4f664b91f6fe6e138c042c5523b8e9ac7972a2";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-eiYt4RM2bdyR4ZAGsi72MW5t54DPgIAbuBVMlWyUb4M=";
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
