{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "xdg-open-svc";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "caarlos0";
      repo = pname;
      rev = "40f0746c5ecb3fa7e0615c0905044d488373cbbf";
      hash = "sha256-Agxqgwjbh6E3xpyWXytjZJBjQFc3NyTzByvOY3eJi+g=";
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
