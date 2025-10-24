{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {
    pname = "claude-code-acp";
    version = "0.5.5-${rev}";
    rev = "dadc7f9f406affa1c8e5d9e26ae2fb6544057f65";

    src = fetchFromGitHub {
      inherit rev;
      owner = "zed-industries";
      repo = "claude-code-acp";
      hash = "sha256-k37+eur36ccLfOlVDlaOnLP6WyZMlWbkRwdo5ix5M/A=";
    };

    doCheck = false;
    dontNpmBuild = true;
    makeCacheWritable = true;
    npmDepsHash = "sha256-ahThcXvpxn8z1q/Jrh1zCK/8MoYDxly2xCIxiF/+ehw=";

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
