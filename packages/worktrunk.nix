{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.20.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-mjWGpWIBeW9rhUoMvBsGo1QNcQ9CFwQk3YjFZ3L6F/M=";
    };

    cargoHash = "sha256-oRyOK0ye/Gv2IK2KNhq7pB7neY3kfyR4XRnzRGLaHWM=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
