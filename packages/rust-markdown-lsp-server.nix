{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "3f9e82f4741a413cea8d10a47b9a03dcff970909";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-qUxwCeemv0Jxi3gATTY75wMchBgS7dobBuJQsfDmKDM=";
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
