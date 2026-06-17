{
  lib,
  pkgs,
  stdenv,
}: let
  pname = "icm";
  version = "0.10.52";

  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-HrBr8l7AAtIlEqx93R/s7xS4/4+jpHG7Mb4JVm6eS2Q=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-mdI0ufjzxlLYwE2QHiL/uxyI3+hfoW+AMhHqMMkXBN4=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  plugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rtk-ai/${pname}/${pname}-v${version}/plugins/opencode-icm.ts";
    hash = "sha256-98chPzOOhHBWHD6T0Rn1Rs/b9jMYFtFsCW6/iFwax0w=";
  };
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

    src = pkgs.fetchurl {
      url = "https://github.com/rtk-ai/${pname}/releases/download/${pname}-v${version}/${pname}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -m755 -D ${pname} $out/bin/${pname}

      # The upstream OpenCode plugin logs to stderr (`[icm] plugin loaded`,
      # `[icm] injected N lines ...`, etc.). OpenCode surfaces plugin stderr
      # in its UI, so that chatter leaks into the conversation view. Strip
      # every console.error/console.warn call (single- and multi-line) before
      # installing. Done here rather than upstream because the plugin is a
      # hash-pinned fetchurl that we cannot edit in place.
      ${pkgs.perl}/bin/perl -0pe 's/^[ \t]*console\.(error|warn)\([^;]*?\);?[ \t]*\n//gms' \
        ${plugin} > opencode-icm.ts
      install -m644 -D opencode-icm.ts $out/plugins/opencode-icm.ts

      runHook postInstall
    '';

    meta = {
      description = "Permanent memory for AI agents. Single binary, zero dependencies, MCP native";
      homepage = "https://github.com/rtk-ai/icm";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
