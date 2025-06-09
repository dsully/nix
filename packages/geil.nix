{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "geil";
    version = "0.0.1-alpha.1";

    src = fetchFromGitHub {
      owner = "Nukesor";
      repo = "geil";
      rev = "3115698c79c17b51bcdff50cbae031672a38684f";
      hash = "sha256-6PetoxRJAg0dnLnww0cTNhfF8k+Tv8U8KkL1HfE8DfQ=";
    };

    cargoHash = "sha256-IcbUQXqoX4kPvGiAFSOhhw7LLfCO0plNBuzv4QondZg=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = "geil";
    };
  }
