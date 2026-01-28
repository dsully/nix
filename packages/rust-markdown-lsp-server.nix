{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-markdown-lsp-server";
    rev = "8dd58743f7ccbdd29fb3e785fc35c2f8b14c331b";
    version = "0.1.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dougrocha";
      repo = "rust_markdown_lsp_server";
      hash = "sha256-UoPacMvrftLCRKodGajoV23F0+Cndlwsn63BoushSLM=";
    };

    cargoHash = "sha256-A23TZkY1OOqn/55FD6s8JCMQO4yHIdiWuxfx02qoZmI=";

    meta = {
      description = "A markdown LSP server for my notes";
      homepage = "https://github.com/dougrocha/rust_markdown_lsp_server";
      license = lib.licenses.mit;
      mainProgram = "rust_markdown_lsp";
    };
  }
