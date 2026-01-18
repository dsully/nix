{
  inputs,
  my,
  pkgs,
  ...
}: let
  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}) neovim;
in {
  home = {
    packages = with pkgs;
      [
        actionlint
        basedpyright
        bash-language-server
        biome
        commitlint-rs
        crates-lsp
        docker-compose-language-service
        dockerfile-language-server
        emmylua-ls
        emmylua-check
        fish-lsp
        gofumpt
        gopls
        harper
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
        ty
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
      ++ (with my.pkgs; [
        codesort
        pyproject
        pyproject-fmt
        pytest-language-server
        xmlformatter
        version-lsp
      ])
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin (with my.pkgs; [
        # lemminx
        # pkl-lsp
      ]);
  };
}
