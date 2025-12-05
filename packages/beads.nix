{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "6789e4fd9ac34c72b412d4204d7daab775da46e3";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-Jsb2rBkelXJgRXkrl1GfpY4gRYPhxP8K+0U26D23TV8=";
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
