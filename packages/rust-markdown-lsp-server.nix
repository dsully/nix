{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "75b3e55a1c262562481e2d0c65c0ade81b9f2a14";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      hash = "sha256-howC3CJQcFeBNNXbmx4vOgKaqtW/aKPhfR/KaJ2rIE8=";
    };

    cargoHash = "sha256-4cgQn7SgtNc2Q+qpP2PH27uCgCZE+JoZVzQT21572c8=";

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
