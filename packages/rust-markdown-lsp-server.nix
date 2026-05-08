{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "9ac5212981ebfe51db45c855ab2fd360e1db03ce";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-WM0hfDJ1/c0peB1GRcGJC+zIrX5nafmPedqgQYmXxok=";
  };

  cargoHash = "sha256-VHJ9dz6MWBWRU75Cx1vWjZvtKMdfTTStr8yS+eZR/cY=";

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
