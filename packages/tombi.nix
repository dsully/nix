{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.13";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "417ba37bd3f987a12b9cffa3125088b8439d13c1";
      hash = "sha256-bUY6x4BrXwbHUC2CynySQlAlCu35MNGjrRB8+Cg/3I0=";
    };

    cargoHash = "sha256-JyYA/Bu1gcj7s5hxx9LOcrN28Klhz3Qy1SbGoWEiwnA=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
