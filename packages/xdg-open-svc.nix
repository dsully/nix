{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "xdg-open-svc";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "caarlos0";
      repo = pname;
      rev = "d716e3b4280d3207219ff6ae541c6b862c9f468e";
      hash = "sha256-knoecIkDbQ0+YAhc6qCEtSpccSsVMAe9C4/4TaBR5AI=";
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
