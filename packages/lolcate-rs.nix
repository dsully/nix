{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "lolcate-rs";
    version = "0.2.2";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "03b1cede298b05a35dcd94a211f043e2d45a2d22";
      hash = "sha256-3S02l9/I53FuXnwL7pnQx6sIzxVnRMxfN7Ftm4OBmbU=";
    };

    cargoHash = "sha256-7p2pBe7gWXw+bnKFBO886AHCNrilPXuGUwf7oAlFx5Y=";
    useFetchCargoVendor = true;

    meta = {
      description = "Lolcate -- A comically fast way of indexing and querying your filesystem. Replaces locate / mlocate / updatedb. Written in Rust";
      homepage = "https://github.com/dsully/lolcate-rs";
      license = lib.licenses.gpl3Only;
      maintainers = ["dsully"];
      mainProgram = "lolcate";
    };
  }
