{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "cd72052eba2c81b5f9a0a1b6da01b11ef3b0db00";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-rhzik5NBw89jEBLkDqJyMsgdN2A/M0J0P4Ml2Z+SXWw=";
  };

  cargoHash = "sha256-VHJ9dz6MWBWRU75Cx1vWjZvtKMdfTTStr8yS+eZR/cY=";

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
