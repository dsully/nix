{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "8ccca53c8999fa3100cbfc029c4ed2c52020cc15";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-nyN984B1s+i8v0faBZpNF0UY0EGkj5H5c7g2kQqBAmM=";
  };

  cargoHash = "sha256-VHJ9dz6MWBWRU75Cx1vWjZvtKMdfTTStr8yS+eZR/cY=";

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
