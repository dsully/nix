{
  lib,
  pkgs,
  my,
  ...
}: {
  home = {
    packages = with pkgs;
      [
        (lib.hiPrio uutils-coreutils-noprefix) # Rust versions of coreutils.
        _1password-cli
        act
        age
        b3sum
        bandwhich
        bat
        bombardier
        btop
        checkip
        chezmoi
        choose
        croc
        curl
        dasel
        delta
        direnv
        dua
        dust
        fclones
        fd
        fishPlugins.plugin-git
        fselect
        fzf
        gnutar
        hexyl
        inetutils
        iperf3
        ipmitool
        just
        kondo
        lsd
        moor
        mtr
        p7zip
        procs
        q
        rip2
        ripgrep
        rnr
        rsync
        sad
        sd
        see-cat
        sniffnet
        topgrade
        tree
        unar
        unzip
        viu
        wget
        xh
        xz
        zellij
        zoxide
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        (caddy.withPlugins
          {
            plugins = [
              "github.com/caddy-dns/cloudflare@v0.2.2-0.20250506153119-35fb8474f57d"
              "github.com/caddy-dns/linode@v0.8.0"
              "github.com/abiosoft/caddy-inspect@v0.0.0-20250214103948-96cdb1dfb122"
              "github.com/abiosoft/caddy-json-schema@v0.0.0-20220621031927-c4d6e132f3af"
            ];
            hash = "sha256-yt6Qax92TIfHBWjiHD+c6gdhZDAOgGkoeIjRVr8KuG8=";
          })
      ]
      ++ [
        my.pkgs.clean-dev-dirs
        my.pkgs.leadr
        my.pkgs.prmt
        my.pkgs.xdg-open-svc
      ];
  };
}
