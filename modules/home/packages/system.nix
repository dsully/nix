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
        checkip
        croc
        curl
        dua
        dust
        fclones
        gnutar
        hexyl
        inetutils
        iperf3
        ipmitool
        just
        lla
        mdterm
        moor
        mtr
        p7zip
        prmt
        procs
        q
        rip2
        rnr
        rsync
        sad
        sd
        tree
        unzip
        viu
        wget
        witr
        xcp
        xh
        xz
      ]
      ++ (with my.pkgs; [
        clean-dev-dirs
        rip-go
        timecop
        xdg-open-svc
      ]);
  };

  packageTools.python = [
    {package = "httptap";}
  ];
}
