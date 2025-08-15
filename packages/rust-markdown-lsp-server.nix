{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "bb25f83ea6b0a4c794eb3b5d85c958918ec0aad4";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      rev = "c4131b5b8289411985eefe84b160df30d4e31437";
      hash = "sha256-fG9bptDCO3xV+dP3BAe24O5pjDONUZjsPKFyskA11dY=";
    };

    cargoHash = "sha256-TEizH+2Y7dGgtBqHc293y1sFirLG2hdf+27TGlsxuyo=";

    # nativeBuildInputs = [
    #   pkg-config
    # ];

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
