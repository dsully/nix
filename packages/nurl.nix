{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "64400df06c16c56bafa3317541f310e68dc82dc2";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-B33olwpUirWu45OgsXVnuQBevt953CyhRVpYVgPyup8=";
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
