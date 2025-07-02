{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  wrapperPath = "/usr/local/bin/shell-wrapper";

  # The same path normalization as performed by the nix-darwin system/shells module.
  normalizeShellPath = shell:
    if types.shellPackage.check shell
    then "/run/current-system/sw${shell.shellPath}"
    else shell;

  shell = config.home.defaultShell;

  # The wrapper waits for /nix to mount and then execs the correct shell for the user
  mkWrapper = _: let
    normalizedShell = normalizeShellPath shell;
    users = {${config.home.username} = normalizedShell;};
  in
    pkgs.callPackage ./wrapper.nix {inherit users;};

  inherit (config.home) username;
in {
  options = {
    home.defaultShell = mkOption {
      type = with types; nullOr package;
      default = null;
      example = literalExpression "pkgs.fish";
      description = ''
        The default shell for the user. On Darwin, this will use a wrapper
        if the shell is a Nix package and FileVault is enabled.
      '';
    };
  };

  config = mkIf (shell != null) {
    home.activation = {
      chsh =
        if types.shellPackage.check shell && pkgs.stdenv.isDarwin
        then
          lib.hm.dag.entryAfter ["writeBoundary"]
          ''
            #!/bin/bash
            if [ ! -x "${wrapperPath}" ]; then
                echo "installing shell wrapper ..." >&2

                /usr/bin/sudo /bin/mkdir -p "$(dirname ${wrapperPath})"
                /usr/bin/sudo /bin/cp ${mkWrapper shell}/bin/shell-wrapper ${wrapperPath}
                /usr/bin/sudo /bin/chmod 0755 "${wrapperPath}"
                /usr/bin/sudo /usr/sbin/chown root ${wrapperPath}
            fi

            if [ "$(dscl . -read /Users/${username} UserShell 2>/dev/null | sed 's/UserShell: //')" != ${wrapperPath} ]; then
                echo "setting default shell for ${username} ..." >&2
                $DRY_RUN_CMD /usr/bin/sudo /usr/bin/chsh -s ${wrapperPath} ${username}
            fi
          ''
        else
          lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''

            SHELL_PATH="${
              if types.shellPackage.check shell
              then getExe shell
              else toString shell
            }"

            ${
              if pkgs.stdenv.isDarwin
              then ''
                #!/bin/bash
                if [ "$(dscl . -read /Users/"$username" UserShell 2> /dev/null | sed 's/UserShell: //')" != "$SHELL_PATH" ]; then
                    echo "setting default shell for ${username} to $SHELL_PATH..." >&2

                    "$DRY_RUN_CMD" /usr/bin/sudo /usr/bin/chsh -s "$SHELL_PATH" "$username"
                fi
              ''
              else ''
                #!/bin/bash

                if [ "$(/usr/bin/getent passwd "$username" | cut -d: -f7)" != "$SHELL_PATH" ]; then
                    echo "setting default shell for ${username} to $SHELL_PATH..." >&2

                    if ! grep -q "$SHELL_PATH" /etc/shells 2> /dev/null; then
                        echo "Adding $SHELL_PATH to /etc/shells"
                        echo "$SHELL_PATH" | /usr/bin/sudo tee -a /etc/shells > /dev/null
                    fi

                    "$DRY_RUN_CMD" /bin/chsh -s "$SHELL_PATH" "$username"
                fi
              ''
            }
          '';
    };
  };
}
