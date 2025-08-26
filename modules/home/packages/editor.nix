{
  inputs,
  my,
  pkgs,
  ...
}: let
  # config-lsp = inputs.config-lsp.packages.${pkgs.system}.default;
  # `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.
  config-lsp = inputs.config-lsp.packages.${pkgs.system}.default;

  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.system}) neovim;
in {
  home = {
    packages = with (pkgs // my.pkgs);
      [
        actionlint
        basedpyright
        bash-language-server
        biome
        commitlint-rs
        config-lsp
        docker-compose-language-service
        dockerfile-language-server-nodejs
        emmylua-analyzer-rust
        fish-lsp
        # gitui
        gofumpt
        gopls
        harper
        imagemagick
        jinja-lsp
        just-lsp
        lemminx
        mado
        marksman
        mbake
        neovim
        nil
        nixd
        nixpkgs-fmt
        oxlint
        prettierd
        pyrefly
        revive
        rstcheck
        ruff
        shellharden
        shfmt
        stylelint
        stylua
        superhtml
        systemd-lsp
        # tectonic-unwrapped
        tombi
        ts_query_ls
        typescript-go
        typos
        vscode-langservers-extracted
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
        pkl-lsp
        pyproject-fmt
        sphinx-lint
        ty
        xmlformatter
        zuban
      ];
  };
}
