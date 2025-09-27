{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {
    pname = "claude-code-acp";
    version = "0.4.5-${rev}";
    rev = "9135a0f1be6ee1740dfa772ecb0b83b00e8c52a8";

    src = fetchFromGitHub {
      inherit rev;
      owner = "zed-industries";
      repo = "claude-code-acp";
      hash = "sha256-kkAQuYP2S5EwIGJV8TLrlYzHOC54vmxEHwwuZD5P1hI=";
    };

    doCheck = false;
    dontNpmBuild = true;
    makeCacheWritable = true;
    npmDepsHash = "sha256-IR88NP1AiR6t/MLDdaZY1Np0AE7wfqEUfmnohaf0ymc=";

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
