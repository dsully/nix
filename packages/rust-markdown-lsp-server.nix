{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "9983db4230632a9bdb419729a6cf43728024b503";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      hash = "sha256-LZC2E2Rzm4Jj+rpcNQhBydj/5PAuVKj/N5FatrGCTyk=";
    };

    cargoHash = "sha256-4cgQn7SgtNc2Q+qpP2PH27uCgCZE+JoZVzQT21572c8=";

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
