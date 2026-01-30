{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "6cbb4631c61b2f7bcc329b1d7eb69d3acc6bd3b6";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      hash = "sha256-vJmSHR4lgcDw5FdnVHmBZhVrtpjg39BK5KcTI0senhk=";
    };

    cargoHash = "sha256-R/t4yaEtCSWKVs3qHxLB8CgCdNtwXDn5YhElac9asNQ=";

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
