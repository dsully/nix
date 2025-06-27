{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "magic-opener";
    version = "0.2.2";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "039003d4a9b11cf338681c3d6093f6b6b91a92cd";
      hash = "sha256-KyJndhXJIgofs+0JbYd7fCJaTXMI8T6rb+7sQc1bUuY=";
    };

    cargoHash = "sha256-wDUPVWQBCGGGkxs+vqBTz/5itKB4lpRpDIPJYAJknJM=";
    useFetchCargoVendor = true;

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
