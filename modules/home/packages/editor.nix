{
  flake,
  inputs,
  pkgs,
  ...
}: let
  local = (flake.inputs.upstream or flake).packages.${pkgs.system} or {};

  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.system}) neovim;

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
        bake
        basedpyright
        bash-language-server
        biome
        ccls
        commitlint-rs
        dockerfile-language-server-nodejs
        emmylua-analyzer-rust
        fish-lsp
        gitui
        gofumpt
        gopls
        harper
        imagemagick
        jinja-lsp
        just-lsp
        lemminx
        mado
        marksman
        mermaid
        neovim
        nil
        nixd
        nixpkgs-fmt
        oxlint
        prettierd
        pyrefly
        python313Packages.jedi-language-server
        revive
        rstcheck
        ruff
        shellharden
        shfmt
        stylelint
        stylua
        superhtml
        systemd-lsp
        tectonic-unwrapped
        tombi
        ts_query_ls
        typos
        vscode-langservers-extracted
        vtsls
        wordnet
        write-good
        (pkgs.yaml-language-server.overrideAttrs (oldAttrs: {
          # Apply patch to source before build
          postPatch =
            (oldAttrs.postPatch or "")
            + ''
              # Patch the TypeScript source
              substituteInPlace src/languageservice/services/yamlValidation.ts \
                --replace "if (isKubernetes && err.message === this.MATCHES_MULTIPLE)" \
                          "if (err.message === this.MATCHES_MULTIPLE)"
            '';
        }))
        yamllint
        zls
      ]
      ++ [
        codesort
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
