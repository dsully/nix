{
  my,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  yamlFormat = pkgs.formats.yaml {};
in {
  config = {
    home = {
      packages = with pkgs;
        [
          actionlint
          basedpyright
          bash-language-server
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
          vimdoc-language-server
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
          neovim
          rust-markdown-lsp-server
          version-lsp
        ]);
    };

    packageTools.python = [
      {package = "lizard";}
      {package = "ptpython";}
      {package = "pyproject";}
      {package = "pyproject-fmt";}
      {package = "pytest-language-server";}
      {package = "python-code-splitter";}
      {package = "xmlformatter";}
    ];

    xdg.configFile = {
      "clangd/config.yaml".source = yamlFormat.generate "clangd-config" {
        CompileFlags = {
          Add = ["-xc++" "-Wall"];
          Remove = [];
          Compiler = "clang++";
        };

        Diagnostics = {
          ClangTidy = {
            Add = [
              "bugprone-*"
              "performance-*"
              "portability-*"
              "readability-*"
              "google-*"
              "misc-*"
              "modernize-*"
            ];
            Remove = "modernize-use-trailing-return-type";
            CheckOptions = {
              "readability-identifier-naming.VariableCase" = "CamelCase";
            };
          };
          UnusedIncludes = "Strict";
        };

        Completion.AllScopes = true;
        Hover.ShowAKA = true;

        InlayHints = {
          Designators = true;
          Enabled = true;
          ParameterNames = true;
          DeducedTypes = true;
        };

        Index.StandardLibrary = "Yes";
      };

      "github-copilot/terms.json".source = jsonFormat.generate "copilot-terms" {
        dsully.version = "2021-10-14";
      };
    };
  };
}
