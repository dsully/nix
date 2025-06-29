{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oxc";
    version = "1.3.0";

    src = fetchFromGitHub {
      owner = "oxc-project";
      repo = pname;
      rev = "46b59d874caa302f48c8a7c18cb21401f13f6f7f";
      hash = "sha256-3TdDnHWshC5zSJZL5EEzhPtrtvRvHU1AQmB0Ttk5kUM=";
    };

    cargoHash = "sha256-fB6VHtN7wI9gGVDbzBkW1f4dP8sibf/JXp8iVu8r/nk=";
    useFetchCargoVendor = true;
    doCheck = false;

    nativeBuildInputs = [
      nodejs
      rustfmt
    ];

    meta = {
      description = "A collection of JavaScript tools written in Rust";
      homepage = "https://github.com/oxc-project/oxc";
      changelog = "https://github.com/oxc-project/oxc/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "oxlint";
    };
  }
