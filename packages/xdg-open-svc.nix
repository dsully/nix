{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "xdg-open-svc";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "caarlos0";
      repo = pname;
      rev = "b194c4510e4751605d667f45a08fca6fec96fb2c";
      hash = "sha256-5YU5wxXowvNMS5k50BCvtOHyrc2ovi9R9Vo7hhR4/Zw=";
    };

    vendorHash = "sha256-scg1vorrJ4a6pblnhEWJeLJjh60uv+PItVU7lCpLGxM=";

    ldflags = ["-s" "-w" "-X=main.version=${version}" "-X=main.builtBy=nixpkgs"];

    meta = with lib; {
      description = "xdg-open as a service";
      homepage = "https://github.com/caarlos0/xdg-open-svc";
      license = licenses.mit;
      mainProgram = pname;
    };
  }
