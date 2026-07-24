{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "bf69c4bba4a7fd2e828f35e494a667c032b6ab05";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-UR1D6+hlzxI5n5JKhmBGYHbsusDo44G1JDpUrskMFRk=";
  };

  cargoHash = "sha256-VHJ9dz6MWBWRU75Cx1vWjZvtKMdfTTStr8yS+eZR/cY=";
  doCheck = false;

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
