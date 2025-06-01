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
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  environment = {
    pathsToLink = ["/share/fish"];

    systemPackages = with pkgs; let
      mine = [
        devmoji-log
        lolcate-rs
        magic-opener
      ];

      forked = [
        git-trim
      ];

      custom = [
        dirstat-rs
        feluda
        geil
      ];

      nix = [
        cachix
        deadnix
        flake-checker
        nh
        nix-converter
        nix-init
        nix-tree
        nix-update
        nixpkgs-lint-community
        njq
        nurl
        nvd
        statix
      ];

      rust = [
        cargo-autoinherit
        cargo-binstall
        cargo-bloat
        cargo-cache
        cargo-clone
        cargo-dist
        cargo-duplicates
        cargo-features-manager
        cargo-insta
        cargo-llvm-lines
        cargo-msrv
        cargo-nextest
        cargo-run-bin
        cargo-shear
        cargo-sweep
        cargo-tarpaulin
        cargo-unused-features
        cargo-update
        cargo-wizard

        (rust-bin.stable.latest.default.override
          {
            extensions = ["rust-analyzer" "rust-src"];
          })

        rustcat
        sccache
      ];

      python = [
        instaloader
        ruff
        rye
        uv
      ];

      files = [
        b3sum
        bat
        choose
        dasel
        delta
        dua
        dust
        fclones
        fd
        fselect
        gnutar
        gomi
        hexyl
        kondo
        lsd
        moar
        p7zip
        rip2
        ripgrep
        rnr
        rsync
        sd
        see-cat
        tree
        unar
        unzip
        viu
        xcp
        xz
      ];

      shell = [
        chezmoi
        direnv
        fish
        fzf
        just
        macchina
        starship
        topgrade
        zellij
        zoxide
      ];

      network = [
        act
        age
        aichat
        bandwhich
        bombardier
        checkip
        croc
        curl
        inetutils
        iperf3
        ipmitool
        mtr
        q
        sniffnet
        wget
        xdg-open-svc
        xh
      ];

      system = [
        (hiPrio uutils-coreutils-noprefix) # Rust versions
        btop
        procs
      ];

      development = [
        better-commits # git bc
        curlconverter
        cyme
        fork-cleaner
        fx
        gh
        ghq
        gibo
        git
        git-dive
        git-ignore
        git-lfs
        git-quick-stats
        git-sizer
        git-who
        glow
        gnused
        go
        gofumpt
        gotools
        gron
        helix
        hyperfine
        jq
        kickstart
        nodejs
        scc
        sq
        sqlite
        tree-sitter
        typos
        vivid
        xan
        yek
        yq
        zig
      ];

      editor = [
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
    in
      mine
      ++ custom
      ++ development
      ++ editor
      ++ files
      ++ forked
      ++ network
      ++ nix
      ++ python
      ++ rust
      ++ shell
      ++ system;
  };
}
