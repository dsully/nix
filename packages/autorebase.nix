{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "autorebase";
    version = "0.6.0";

    src = fetchFromGitHub {
      owner = "Timmmm";
      repo = "autorebase";
      rev = "ea257cae8d61ffcf2a5bb15c61806f4ac08fb5b3";
      hash = "sha256-xREhcZBX3jIprfYfErl+UAy8+/EMFFlmCCjLHuNHF+0=";
    };

    cargoHash = "sha256-s08cFckRyFqrIe/oPyJF+SFMkB/thghobU8iGly4zuI=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "Automatically rebase all your branches onto master";
      homepage = "https://github.com/Timmmm/autorebase";
      # license = lib.licenses.unfree;
      mainProgram = "autorebase";
    };
  }
