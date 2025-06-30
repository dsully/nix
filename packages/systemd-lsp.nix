{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "systemd-lsp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "JFryy";
      repo = pname;
      rev = "43e0a26b12653b97939612ce8f4e2f3bae562ea1";
      hash = "sha256-l2/8khzXZjyga4nEdl4pcl3AOscCBxZHH3tW3Cv+RUk=";
    };

    cargoHash = "sha256-bYksgHTXomeEJuSk800+/PYXzMvrixSjfPnoqxStWAA=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "A language server implementation for systemd unit files made in rust";
      homepage = "https://github.com/JFryy/systemd-lsp";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
