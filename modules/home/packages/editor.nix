{
  my,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  yamlFormat = pkgs.formats.yaml {};
in {
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
        # 4.10.0's bundled servers mix CommonJS `require()` with `createRequire(import.meta.url)`.
        # Node sees `import.meta`, reparses the file as ESM, and the top-level `require()` calls
        # throw "require is not defined in ES module scope", crashing jsonls on startup.
        # Drop the redundant ESM shim so the bundles parse and run as CommonJS again.
        (vscode-langservers-extracted.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + ''
              find "$out" -name '*.js' -path '*node*' -print0 \
                | xargs -0 sed -i \
                    -e 's/(0, _module\.createRequire)(import\.meta\.url)/require/g' \
                    -e 's/createRequire(import\.meta\.url)/require/g'
            '';
        }))
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

  programs.uv.tool.packages = [
    "lizard"
    "ptpython"
    "pyproject"
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

    "github-copilot/terms.json".source = jsonFormat.generate "copilot-terms" {
      dsully.version = "2021-10-14";
    };
  };
}
