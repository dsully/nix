{
  flake,
  inputs,
  pkgs,
  ...
}: let
  yaml-language-server-patched = pkgs.yaml-language-server.overrideAttrs (oldAttrs: {
    # Apply patch to source before build
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        # Patch the TypeScript source
        substituteInPlace src/languageservice/services/yamlValidation.ts \
          --replace "if (isKubernetes && err.message === this.MATCHES_MULTIPLE)" \
                    "if (err.message === this.MATCHES_MULTIPLE)"
      '';
  });

  local =
    (flake.inputs.upstream or flake).packages.${pkgs.system} or {};

  inherit (inputs.emmylua-analyzer-rust.packages.${pkgs.system}) emmylua_ls;
  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.system}) neovim;

  tombi = inputs.tombi.packages.${pkgs.system}.default;

  # Address: https://discourse.nixos.org/t/mermaid-cli-on-macos/45096/3
  mermaid =
    if pkgs.stdenv.isDarwin
    then pkgs.mermaid-cli.override {inherit (local) chromium;}
    else pkgs.mermaid-cli;
in {
  home = {
    packages = with (pkgs // local);
      [
        actionlint
        alejandra
        ast-grep
        basedpyright
        bash-language-server
        biome
        ccls
        commitlint-rs
        dockerfile-language-server-nodejs
        emmylua_ls
        fish-lsp
        gitui
        gofumpt
        gopls
        gotools
        harper
        imagemagick
        jinja-lsp
        just-lsp
        lemminx
        markdownlint-cli2
        marksman
        mermaid
        neovim
        nil
        nixd
        nixpkgs-fmt
        prettierd
        protolint
        revive
        rstcheck
        ruff
        shellharden
        shfmt
        stylelint
        stylua
        superhtml
        taplo
        tectonic-unwrapped
        tombi
        ts_query_ls
        typos
        vscode-langservers-extracted
        vtsls
        write-good
        yaml-language-server-patched
        yamllint
        zls
      ]
      ++ [
        codesort
        ghostty-ls
        gh-actions-language-server
        pkl-lsp
        pyproject-fmt
        sith-language-server
        sphinx-lint
        ty
        xmlformatter
      ];
  };
}
