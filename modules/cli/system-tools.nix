{
  mkUserModule,
  lib,
  pkgs,
  my,
  ...
}:
mkUserModule {
  name = "system-tools";

  home = {
    home = {
      packages = with pkgs;
        [
          (lib.hiPrio uutils-coreutils-noprefix) # Rust versions of coreutils.
          _1password-cli
          croc
          curl
          dirstat-rs
          dua
          dust
          fclones
          gnutar
          hexyl
          inetutils
          iperf3
          ipmitool
          just
          mdterm
          moor
          p7zip
          q
          rip2
          rnr
          rsync
          sad
          sd
          tree
          ttl
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
          xdg-open-svc
        ]);
    };

    programs.uv.tool.packages = [
      "httptap"
    ];
  };
}
