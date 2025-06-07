{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      (hiPrio uutils-coreutils-noprefix) # Rust versions
      act
      age
      aichat
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
      (pkgs.direnv.overrideAttrs (oldAttrs: {
        doCheck = false;
        patches =
          (oldAttrs.patches or [])
          ++ [
            (pkgs.fetchpatch {
              url = "https://github.com/direnv/direnv/pull/1426.patch";
              sha256 = "sha256-qK4wT4+jZdzLBWm5m0up/VZWiUw9kzS9FhM0NsC/DZo=";
            })
          ];
      }))
      dua
      dust
      fclones
      fd
      fselect
      fzf
      gnutar
      gomi
      hexyl
      inetutils
      iperf3
      ipmitool
      just
      kondo
      lsd
      macchina
      moar
      mtr
      p7zip
      procs
      q
      rip2
      ripgrep
      rnr
      rsync
      sd
      see-cat
      sniffnet
      starship
      topgrade
      tree
      unar
      unzip
      viu
      wget
      xcp
      xdg-open-svc
      xh
      xz
      zellij
      zoxide
    ];
  };
}
