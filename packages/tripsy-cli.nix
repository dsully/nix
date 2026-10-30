{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin_arm64";
      hash = "sha256-MZNZZTV3uDgiYVDTM4IY/cES0SUAOnHDAgSC9CWPsuw=";
    };
    x86_64-linux = {
      suffix = "linux_amd64";
      hash = "sha256-fCWePEb5JQ/PN4Dsju9CTvXrhJMfMr671LANKwj+pug=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "tripsy";
    version = "2.2.0";

    src = pkgs.fetchurl {
      url = "https://github.com/tripsyapp/cli/releases/download/v${version}/tripsy_${version}_${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    nativeBuildInputs = with pkgs; [installShellFiles jq];

    installPhase = ''
      runHook preInstall

      install -m755 -D -t $out/bin tripsy tripsy-mcp

      runHook postInstall
    '';

    # tripsy has no completion generator, so derive one from its JSON command listing.
    postInstall = ''
      installShellCompletion --cmd tripsy --fish <($out/bin/tripsy --help | jq -r '.data[] |
        "complete -c tripsy -n __fish_use_subcommand -a \(.name) -d \(.summary | @sh)",
        (select(.subcommands) | (.subcommands | join(" ")) as $subs |
          "complete -c tripsy -f -n \("__fish_seen_subcommand_from \(.name); and not __fish_seen_subcommand_from \($subs)" | @sh) -a \($subs | @sh)")')
    '';

    meta = {
      description = "Command-line client and MCP server for the public Tripsy API";
      longDescription = ''
        tripsy is a command-line client for the public Tripsy API at https://api.tripsy.app.
        The project also ships tripsy-mcp, a Model Context Protocol server that exposes
        typed Tripsy tools for agents and MCP-capable apps.
      '';
      homepage = "https://github.com/tripsyapp/cli";
      license = lib.licenses.unfree;
      mainProgram = pname;
    };
  }
