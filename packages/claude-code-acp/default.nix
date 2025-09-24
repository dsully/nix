{pkgs, ...}:
with pkgs;
  buildNpmPackage rec {

  pname = "claude-code-acp";
  version = "0.4.3";

  src = fetchzip {
    url = "https://registry.npmjs.org/@zed-industries/claude-code-acp/-/claude-code-acp-${version}.tgz";
    hash = "sha256-/zOy0Xo1fvJrABRRpzMhGD6UdryzlHDNPxQFotdWtL0=";
  };

  npmDepsHash = "sha256-IIs5zV35DnZQ6vIeg0JxT8YBHCm7E0DJOKebwA1WXqE=";

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
