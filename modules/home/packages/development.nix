{
  config,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
in {
  home = {
    file = {
      ".typos.toml".source = tomlFormat.generate "typos-config" {
        default = {
          extend-ignore-re = [
            "\\[[0-9a-f]{7}\\]"
            "(?Rm)^.*(#|--|//)\\s*spellchecker:disable-line$"
            "(?s)(#|--|//|)\\s*spellchecker:off.*?\\n\\s*(#|--|//)\\s*spellchecker:on"
            "\\bTLS_[A-Z0-9_]+(_anon_[A-Z0-9_]+)?\\b"
          ];
          extend-ignore-words-re = [
            "\\A[a-zA-Z]{1,3}\\z"
          ];
          extend-words = {
            AKS = "AKS";
            aks = "aks";
            electricrain = "electricrain";
            iterm = "iterm";
            noice = "noice";
            protols = "protols";
          };
        };

        files.extend-exclude = [
          "*.css"
          "*.lock"
          "*.min.css"
          "*.min.js"
          "*.plist"
          "*lock.json"
          ".git/"
          ".github/"
          ".typos.toml"
          "_typos.toml"
          "go.mod"
          "go.sum"
          "node_modules"
          "pnpm-lock.yaml"
          "typos.toml"
          "vendor/**/*"
        ];

        "type.fish".extend-words = {
          doas = "doas";
        };

        "type.lua".extend-words = {
          enew = "enew";
          vhyrro = "vhyrro";
          "}," = "},";
        };

        "type.rust".extend-words = {
          juxt = "juxt";
          ratatui = "ratatui";
        };

        "type.toml" = {};
        "type.toml.pyproject" = {};
        "type.toml.pyproject.extend-words"."]" = "]";
      };
    };

    packages = with pkgs; [
      ast-grep
      codebook
      cyme
      difftastic
      dive
      gibo
      gnused
      go
      hyperfine
      jq
      nodejs
      scc
      sq
      sqlite
      tree-sitter
      typos
      xan
      yarn
      yq-go
    ];

    sessionVariables = {
      GOPATH = "${config.xdg.dataHome}/go";
    };
  };

  programs.go = {
    enable = true;
    env.GOPATH = "${config.xdg.dataHome}/go";
  };
}
