{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "6357821ea371fdba1bb446c99a9f6e0e13584c2e";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      hash = "sha256-I9huDUHq/gfAhwhUUj2Spq77DNZ+4cZl0JalBXVJFZE=";
    };

    cargoHash = "sha256-A23TZkY1OOqn/55FD6s8JCMQO4yHIdiWuxfx02qoZmI=";

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
