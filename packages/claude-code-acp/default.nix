{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {
    pname = "claude-code-acp";
    version = "0.4.7-${rev}";
    rev = "600a2db82f209eaae02aa92f5044fed675ad53e4";

    src = fetchFromGitHub {
      inherit rev;
      owner = "zed-industries";
      repo = "claude-code-acp";
      hash = "sha256-+lZJJx0zsi6Pb51QpjdOTmQtp9k95OW520EWDqfboF4=";
    };

    doCheck = false;
    dontNpmBuild = true;
    makeCacheWritable = true;
    npmDepsHash = "sha256-j4lcOsvSHr34q9IDefOWASe5RTAtTxoPNLmCDw5ahy8=";

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
