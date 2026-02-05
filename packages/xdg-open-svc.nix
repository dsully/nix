{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "xdg-open-svc";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "caarlos0";
      repo = pname;
      rev = "639c1dacd375ea30d6dd0ba98e80cea05abce5c0";
      hash = "sha256-T87O8Ln8W1hfgTlKswBlT3D2hOdQ4T5vpgdiYr8NEJ4=";
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
