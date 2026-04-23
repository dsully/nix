{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "d913d9ff9a512f6273479922cc80bb75575a5766";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-wsmpCKJh6rHiA2IgmBWsspfq7A7lywT0Dp8T8NNJOso=";
  };

  cargoHash = "sha256-3HqA9iFxs5xzC4bclP9g67yM1ROxk/VBcknYicnMSg4=";

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
