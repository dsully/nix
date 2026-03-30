{
  inputs,
  my,
  pkgs,
  ...
}: let
  inherit (inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}) neovim;
in {
  config.packageTools.python = [
    {package = "lizard";}
    {package = "ptpython";}
    {package = "pyproject";}
    {package = "pyproject-fmt";}
    {package = "pytest-language-server";}
    {package = "xmlformatter";}
  ];

  config.home = {
    sessionVariables.VIMRUNTIME = "${neovim}/share/nvim/runtime";

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
        oxfmt
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
      ]
      ++ [
        luajitPackages.busted
        luajitPackages.luarocks
        luajitPackages.nlua
      ]
      ++ (with my.pkgs; [
        codesort
        rust-markdown-lsp-server
        version-lsp
        vimdoc-language-server
      ]);
  };
}
