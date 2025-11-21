{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "xdg-open-svc";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "caarlos0";
      repo = pname;
      rev = "9b7b82aa77be38f72d4c3d5e59315342d9bf6eb7";
      hash = "sha256-/uTqWY2E0bgJ3pQyRO5cJG8Mpq/f491ydOQqGKpN1uk=";
    };

    vendorHash = "sha256-2E2++3AHJmt3Srsz5yBYK0R0GCjG9ITn35y/XDyOboE=";

    ldflags = ["-s" "-w" "-X=main.version=${version}" "-X=main.builtBy=nixpkgs"];

    meta = with lib; {
      description = "xdg-open as a service";
      homepage = "https://github.com/caarlos0/xdg-open-svc";
      license = licenses.mit;
      mainProgram = pname;
    };
  }
