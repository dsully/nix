{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "magic-opener";
    version = "0.2.1";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "magic-opener";
      rev = "132fb9d24d00b93d5b3d49a0053c0ee9c0171f96";
      hash = "sha256-nHRXGXcxOQt+ZzAWd0p6god4GkZbO3eiUCx7M5CzebM=";
    };

    cargoHash = "sha256-zhhbvOhP7fM5vSwts6uAmEkx1hRPg9zEs13bXPQ46VE=";
    useFetchCargoVendor = true;

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
