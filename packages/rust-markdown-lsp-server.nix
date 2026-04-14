{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "3b0916b51b4ad35645282a41554cce12b19ac469";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-/l6sLsa2S8XXS3SXUaJqzaALxV1oUVtTqRW7PKzsvC8=";
  };

  cargoHash = "sha256-BYlHcon/OvtPeYHFZvA4NoERPtaEYq5reXFlekxwJS0=";

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
