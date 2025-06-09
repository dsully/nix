{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "lolcate-rs";
    version = "0.2.2";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "241d31b672bc46b4081414248808eb66637f1756";
      hash = "sha256-sWriyh4BglPyj+2kJPsbsrkjhUpHN6HSS/4DJJ2c6zs=";
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
