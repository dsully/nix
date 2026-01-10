{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "rip-go";
    rev = "a8b499dc8e4063132e34423c1deedeb8fdbe763f";
    version = "0.2.2";

    src = fetchFromGitHub {
      inherit rev;
      owner = "roniel-rhack";
      repo = "rip-go";
      hash = "sha256-qrscIT5eTRNnB3o6RNc7CNZhjiym/PwFJ+jYRx5c8pM=";
    };

    vendorHash = "sha256-Q6AstIIHJwmi6JHNQEAr2c5dZSXbDQSbqIvCxgyXuJ8=";
    doCheck = false;

    ldflags = ["-s" "-w"];

    meta = {
      description = "Fuzzy find and kill processes from your terminal with real-time updates";
      homepage = "https://github.com/roniel-rhack/rip-go";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
