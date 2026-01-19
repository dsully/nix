{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.15.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-c2NzbK4CNP+BcLjm+JcsWXFuLYfaM35mSh0btTt1iIA=";
    };

    cargoHash = "sha256-+hISt0DBI5T/3BQnp5UO17pn0acoHgvHo6iXGUXUYkM=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
