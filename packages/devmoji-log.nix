{pkgs, ...}:
with pkgs;
# {
#   lib,
#   rustPlatform,
#   fetchFromGitHub,
#   pkg-config,
#   libgit2,
#   zlib,
#   ...
# }:
  rustPlatform.buildRustPackage {
    pname = "devmoji-log";
    version = "0.0.1";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "devmoji-log";
      rev = "71d3cde4d35013be11b411d843beb51509fcfc8b";
      hash = "sha256-xuDu//ORJ0ClKt5nrW2b8gzmGXyjepAO7VzHx14kQOY=";
    };

    cargoHash = "sha256-YqmmY+XxFD1W92fnDmcEdyQ+9WOn6rTBLofJ+LxeDeM=";
    useFetchCargoVendor = true;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libgit2
      zlib
    ];

    meta = {
      description = "Display Git commit history with conventional commit types and gitmojis";
      homepage = "https://github.com/dsully/devmoji-log";
      license = lib.licenses.mit;
      maintainers = ["dsully"];
      mainProgram = "devmoji-log";
    };
  }
