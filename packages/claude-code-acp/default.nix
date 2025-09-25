{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {

  pname = "claude-code-acp";
  version = "0.4.4";

  src = fetchzip {
    url = "https://registry.npmjs.org/@zed-industries/claude-code-acp/-/claude-code-acp-${version}.tgz";
    hash = "sha256-kkAQuYP2S5EwIGJV8TLrlYzHOC54vmxEHwwuZD5P1hI=";
  };

  npmDepsHash = "sha256-tfsSjCATaP43dsylWRcy5KOCoO7taS88V49tRwveFjg=";
  makeCacheWritable = true;

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

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
