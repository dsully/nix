{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "lolcate-rs";
    version = "0.2.3";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "aa7325587c3214c17337ab405708c6af2b7f44b8";
      hash = "sha256-IyGsDvgwzSAYGupdil5RUPDdzG11f/EdtWPa8yyBmHg=";
    };

    cargoHash = "sha256-ktaf+dkhxojj0xbGij02EN7nb8oTLCcaSpzLcRk4wXE=";

    meta = {
      description = "Lolcate -- A comically fast way of indexing and querying your filesystem. Replaces locate / mlocate / updatedb. Written in Rust";
      homepage = "https://github.com/dsully/lolcate-rs";
      license = lib.licenses.gpl3Only;
      maintainers = ["dsully"];
      mainProgram = "lolcate";
    };
  }
