# Fix mermaid: https://discourse.nixos.org/t/mermaid-cli-on-macos/45096/3
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

  inherit
    (inputs.emmylua-analyzer-rust.packages.${pkgs.system})
    emmylua_check
    emmylua_ls
    ;
in {
  home = {
    packages = with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {}));
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
        emmylua_check
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
        lua-language-server
        luajit
        markdownlint-cli2
        marksman
        mermaid-cli
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
