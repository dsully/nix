# Fix mermaid: https://discourse.nixos.org/t/mermaid-cli-on-macos/45096/3
{pkgs, ...}: let
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
in {
  home = {
    packages = with pkgs; [
      actionlint
      alejandra
      ast-grep
      basedpyright
      bash-language-server
      biome
      buildifier
      ccls
      codesort
      commitlint-rs
      dockerfile-language-server-nodejs
      emmylua_check
      emmylua_ls
      fish-lsp
      ghostty-ls
      gh-actions-language-server
      gitui
      gofumpt
      gopls
      gotools
      harper
      imagemagick
      jinja-lsp
      just-lsp
      lemminx
      lua-language-server
      luajit
      markdownlint-cli2
      marksman
      mermaid-cli
      neovim
      nil
      nixd
      nixpkgs-fmt
      pkl-lsp
      prettierd
      protolint
      pyproject-fmt
      revive
      rstcheck
      ruff
      shellharden
      shfmt
      sith-language-server
      sphinx-lint
      stylelint
      stylua
      superhtml
      taplo
      tectonic-unwrapped
      ts_query_ls
      ty
      typos
      vscode-langservers-extracted
      vtsls
      write-good
      xmlformatter
      yaml-language-server-patched
      yamllint
      zls
    ];
  };
}
