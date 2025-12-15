{
  inputs,
  my,
  pkgs,
  ...
}: let
  # config-lsp = inputs.config-lsp.packages.${pkgs.system}.default;
  # `perSystem.nixos-anywhere.default` is a shorthand for `inputs.nixos-anywhere.packages.<system>.default`.
  config-lsp = inputs.config-lsp.packages.${pkgs.stdenv.hostPlatform.system}.default;

  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}) neovim;
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
        crates-lsp
        docker-compose-language-service
        dockerfile-language-server
        emmylua-ls
        emmylua-check
        fish-lsp
        gitui
        gofumpt
        gopls
        harper
        imagemagick
        jinja-lsp
        just-lsp
        mbake
        neovim
        nil
        nixd
        nixpkgs-fmt
        oxlint
        pyrefly
        revive
        rstcheck
        ruff
        rumdl
        shellharden
        shfmt
        sphinx-lint
        stylelint
        stylua
        superhtml
        systemd-lsp
        tombi
        ts_query_ls
        typescript-go
        typos
        vscode-langservers-extracted
        wordnet
        write-good
        yaml-language-server
        # (pkgs.yaml-language-server.overrideAttrs (oldAttrs: {
        #   # Apply patch to source before build
        #   postPatch =
        #     (oldAttrs.postPatch or "")
        #     + ''
        #       # Patch the TypeScript source
        #       substituteInPlace src/languageservice/services/yamlValidation.ts \
        #         --replace "if (isKubernetes && err.message === this.MATCHES_MULTIPLE)" \
        #                   "if (err.message === this.MATCHES_MULTIPLE)"
        #     '';
        # }))
        yamllint
        zls
      ]
      ++ [
        codesort
        pyproject
        pyproject-fmt
        pytest-language-server
        ty
        xmlformatter
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        # lemminx
        # pkl-lsp
      ];
  };
}
