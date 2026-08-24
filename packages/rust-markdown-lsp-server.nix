{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "35b667e8923ad4e7a4a419d834093fd607e8b953";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-r+nROcSZw+mveJf3jdGRpSqGKd4o9DQGfDouqfz/+Sc=";
  };

  cargoHash = "sha256-juGXpBNwmZjk5uTesykwaxbnWTI90xrsFZNEI2KLG8c=";
  doCheck = false;

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
