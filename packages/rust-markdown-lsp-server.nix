{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "7b1cd5d7e7c1300c64e169f8be3e127a4b1b0028";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      rev = "c4131b5b8289411985eefe84b160df30d4e31437";
      hash = "sha256-MZlaxx9G5viHkFsOOXbV3CLcIr+e+sibplLw7WEYkhg=";
    };

    cargoHash = "sha256-4cgQn7SgtNc2Q+qpP2PH27uCgCZE+JoZVzQT21572c8=";

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
