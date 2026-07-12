{
  config,
  lib,
  pkgs,
  sudoLib,
  ...
}: {
  imports = [
    ../common/nix.nix
  ];

  nix = lib.mkMerge [
    {
      settings =
        config.system.nixSettings
        // {
          # NixOS's config/nix.nix (imported by system-manager) appends
          # "https://cache.nixos.org/" via mkAfter and prepends the
          # cache.nixos.org public key as plain list defaults, both of which
          # would duplicate our already-configured entries. Override them with
          # mkOverride 0 (max priority) to prevent the concatenation.
          substituters = lib.mkOverride 0 config.system.nixSettings.substituters;
          trusted-public-keys = lib.mkOverride 0 config.system.nixSettings.trusted-public-keys;
        };
    }

    # https://lix.systems/add-to-config/
    (lib.mkIf (config.system.nixFlavor == "lix") {
      enable = true;
      package = pkgs.lixPackageSets.latest.lix;
    })
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Shared sshd hardening + AcceptEnv (so jarvis can pass SSH_CLIENT_* paths,
  # consumed by the `tower` fish fn). Applies to every Linux host; Darwin hosts
  # get the equivalent via modules/darwin/common.nix. Takes effect only after
  # sshd is reloaded. NOTE: no Subsystem here -- the stock sshd_config already
  # defines `Subsystem sftp`, and a duplicate definition is fatal to sshd.
  environment.etc."ssh/sshd_config.d/10-local.conf" = {
    source = ./files/sshd-10-local.conf;
    replaceExisting = true;
  };

  # Enabling the vendored NixOS security.sudo module replaces the host's
  # /etc/sudoers (adapter sets replaceExisting). The generated file still ends
  # with `@includedir /etc/sudoers.d`, so the existing per-host drop-ins keep
  # working. We must reproduce Debian's base rules here or lose general sudo.
  security.sudo = {
    enable = true;

    # Broad access first, then the specific NOPASSWD rules from system.sudoRules
    # (ttl). sudo is last-match-wins, so the specific rules must come last.
    extraRules =
      [
        {
          groups = ["sudo"];
          runAs = "ALL:ALL";
          commands = [{command = "ALL";}];
        }
        {
          groups = ["admin"];
          runAs = "ALL";
          commands = [{command = "ALL";}];
        }
      ]
      ++ sudoLib.toExtraRules config.system.sudoRules
      ++ [
        # Passwordless `nh clean` for `just gc`. SETENV lets
        # sudo --preserve-env=HOME through so nh finds the home-manager
        # profile; nix is on secure_path below. Keep the args in sync with
        # NH_CLEAN_ARGS in the Justfile.
        {
          users = [config.system.userName];
          runAs = "root";
          commands = [
            {
              command = "/nix/store/*/bin/nh clean all --no-gcroots --no-direnv --optimise --keep-one --cross-filesystems";
              options = ["NOPASSWD" "SETENV"];
            }
          ];
        }
      ];

    # Preserve the host's curated /etc/sudoers Defaults (secure_path + the
    # env_keep block) that the takeover would otherwise drop.
    extraConfig = ''
      Defaults env_reset
      Defaults mail_badpass
      Defaults secure_path="/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
      Defaults use_pty
      Defaults:%sudo env_keep += "EDITOR"
      Defaults:%sudo env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK"
      Defaults:%sudo env_keep += "BATPIPE FZF_DEFAULT_OPTS GO111MODULE LS_COLORS MANPAGER PAGER RIPGREP_CONFIG_PATH _ZO_FZF_OPTS"
      Defaults:%sudo env_keep += "PATH TERM TERMINFO"
    '';
  };
}
