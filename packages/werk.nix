{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "werk";
    version = "unstable-2025-02-25";

    src = fetchFromGitHub {
      owner = "simonask";
      repo = pname;
      rev = "e57ce24a87654c9cdd19b4136842d701a06fe3d0";
      hash = "sha256-688+6K0jqMn6WIWobIg14fru6HMvmnBMzQxfKoT3A/c=";
    };

    cargoHash = "sha256-36eRw6vySQP1qLHIb9BF+K0YbyO5YYT74HAWfIMvyBo=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "Simplistic command runner and build system";
      homepage = "https://github.com/simonask/werk";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
