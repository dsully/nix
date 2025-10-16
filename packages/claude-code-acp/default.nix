{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {
    pname = "claude-code-acp";
    version = "0.5.5-${rev}";
    rev = "2c16a41fa4b9be7f93ceb4899f33461cb1e3a88e";

    src = fetchFromGitHub {
      inherit rev;
      owner = "zed-industries";
      repo = "claude-code-acp";
      hash = "sha256-KVpY2ADJA0kreL2uLO2XcJqcEDr9RrUgS+I4UtN/9wc=";
    };

    doCheck = false;
    dontNpmBuild = true;
    makeCacheWritable = true;
    npmDepsHash = "sha256-6U62xC30c1BwTWcfh2Sw5AfHY7nj+VdC84Joa8x2p3A=";

    nativeBuildInputs = [
      pkgs.patchelf
    ];

    postPatch = ''
      cp ${./package-lock.json} package-lock.json
    '';

    AUTHORIZED = "1";

    # `claude-code` tries to auto-update by default, this disables that functionality.
    # https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview#environment-variables
    postInstall = ''
      wrapProgram $out/bin/claude-code-acp \
        --set DISABLE_AUTOUPDATER 1
    '';

    passthru.updateScript = ./update.sh;

    meta = {
      description = "An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster";
      homepage = "https://github.com/zed-industries/claude-code-acp";
      downloadPage = "https://www.npmjs.com/package/@zed-industries/claude-code-acp";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "claude-code-acp";
    };
  }
