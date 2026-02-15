{
  flake,
  lib,
  ...
}: {
  # Disable home-manager via nix-darwin
  #
  # https://github.com/numtide/blueprint/issues/116
  home-manager.users = lib.mkForce {};

  imports = [
    flake.modules.darwin.common
    flake.modules.darwin.homebrew
    ./homebrew.nix
    ./options.nix
  ];

  environment.etc = {
    "hosts".text = ''
      ##
      # Host Database
      ##
      127.0.0.1	localhost
      255.255.255.255	broadcasthost
      ::1             localhost
      10.0.0.100      server

      # https://gist.github.com/henrik242/65d26a7deca30bdb9828e183809690bd
      0.0.0.0 albert.apple.com
      0.0.0.0 iprofiles.apple.com
      0.0.0.0 mdmenrollment.apple.com
      0.0.0.0 deviceenrollment.apple.com
      0.0.0.0 gdmf.apple.com
    '';

    "nsmb.conf".text = ''
      [default]
      signing_required=no
      validate_neg_off=yes
      port445=no_netbios
      protocol_vers_map=4
      streams=yes
      soft=yes
    '';
  };
}
