{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-markdown-lsp-server";
  rev = "cf279cfca85f11f54df1d4612487efc02e7dff17";
  version = "0.1.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dougrocha";
    repo = "rust_markdown_lsp_server";
    hash = "sha256-dJmxtQP18hUEZrMXQE1w0Hl8sj2j/rzWbGrYYdFK9pg=";
  };

  cargoHash = "sha256-gpELnRo/hAheGoFq3Nx5hPkcpmNLelMSlBcWHsF2KwU=";

  meta = {
    description = "A markdown LSP server for my notes";
    homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
    license = lib.licenses.mit;
    mainProgram = "rust_markdown_lsp";
  };
}
