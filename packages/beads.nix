{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "beads";
    version = "0.23.0";
    rev = "060c2b68c74e13ddd7e0e054657b7a4cef2f41c1";

    src = fetchFromGitHub {
      inherit rev;
      owner = "steveyegge";
      repo = "beads";
      hash = "sha256-yWf8MXO9mYB0q+P3ueVq1NDeMYi2+8D1LvJ2eP2KoY8=";
    };

    vendorHash = "sha256-5p4bHTBB6X30FosIn6rkMDJoap8tOvB7bLmVKsy09D8=";
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
