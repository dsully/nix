{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "6ae54dfe1de4d7094b20c0896e3e2ef4a3fddad5";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-JHwEnl5JMjbCyapqsB6p7gztTm7zaISi8tnU8Vdjb0o=";
    };

    cargoHash = "sha256-hcpQ1aKnq+w8xKE6FQ/PycLqL7o2ZuMhIRO2LfsZ7go=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
