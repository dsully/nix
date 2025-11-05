{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "crates-mcp";
    version = "0.1.0";

    src = fetchFromGitHub {
      owner = "pato";
      repo = pname;
      rev = "d313c94d709f324c119b4b34354761a45ca87cb0";
      hash = "sha256-bVOoPNb35JlmDA60plmsBKHqNw/P4quG/8ZwWGx80sQ=";
    };

    cargoHash = "sha256-NV8ewbAqMerH+AMU5IBR+OINaZ0oyxgE2wxQXbhI7j4=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
      zlib
    ];

    meta = {
      description = "A local MCP server used to fetch Rust crate information and docs from crates.io and docs.rs";
      homepage = "https://github.com/pato/crates-mcp";
      mainProgram = pname;
    };
  }
