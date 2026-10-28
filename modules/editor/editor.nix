{
  mkUserModule,
  my,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};
in
  mkUserModule {
    name = "editor";

    home = {
      home = {
        packages = with pkgs;
          [
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
            oxfmt
            oxlint
            pyrefly
            revive
            ruff
            rumdl
            stylelint
            stylua
            superhtml
            swiftlint
            tombi
            ts_query_ls
            ty
            typescript
            typos-lsp
            vimdoc-language-server
            vscode-langservers-extracted
            xcodegen
            yaml-language-server
            yamllint
          ]
          ++ [
            luajitPackages.busted
            luajitPackages.luarocks
            luajitPackages.nlua
          ]
          ++ (with my.pkgs; [
            neovim
            rust-markdown-lsp-server
            shell-lsp
            version-lsp
          ]);
      };

      programs.uv.tool.packages = [
        "pyproject-fmt"
        "pytest-language-server"
        "python-code-splitter"
        "xmlformatter"
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
      };
    };
  }
