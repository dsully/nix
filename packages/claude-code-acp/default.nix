{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {
    pname = "claude-code-acp";
    version = "0.5.5-${rev}";
    rev = "8aea8fd0e120b6ae752adc66cd05cc5ff669c1ce";

    src = fetchFromGitHub {
      inherit rev;
      owner = "zed-industries";
      repo = "claude-code-acp";
      hash = "sha256-v32Q02ALWw6Upd4rrHGZH7Vt25+xSnKJCNGJob/irgM=";
    };

    doCheck = false;
    dontNpmBuild = true;
    makeCacheWritable = true;
    npmDepsHash = "sha256-oUAHkB4EPuo8YCxi9Y/Lc8cipjJQ05o51MpdUsCjiiQ=";

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
