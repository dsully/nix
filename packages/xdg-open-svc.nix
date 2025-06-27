{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "xdg-open-svc";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "caarlos0";
      repo = pname;
      rev = "65283ef6cd6ac632a749d41b5822e7d832733555";
      hash = "sha256-YCKiM/J76ajMCj15vtTtvCq51Whfv05Fw+4ebJgVMjY=";
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
