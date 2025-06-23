{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.13";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "aefa853123ce5e84b8a000c067737f8d0bad57ab";
      hash = "sha256-+0yzy2cysgZbccvt93Fls7xg7ieyq+cVpbFsV8x6cgQ=";
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
