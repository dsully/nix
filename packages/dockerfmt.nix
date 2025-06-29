{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "dockerfmt";
    version = "0.3.7";

    src = fetchFromGitHub {
      owner = "reteps";
      repo = pname;
      rev = "bae08be700b6dbde8a3381b49b97c4b8ce1559a5";
      hash = "sha256-n8ijgYbFqqgRUhI1MD8Pw5ytan1yJ5bReEtRkWn90sU=";
    };

    vendorHash = "sha256-fLGgvAxSAiVSrsnF7r7EpPKCOOD9jzUsXxVQNWjYq80=";

    ldflags = ["-s" "-w"];

    meta = {
      description = "Dockerfile formatter. a modern dockfmt";
      homepage = "https://github.com/reteps/dockerfmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
