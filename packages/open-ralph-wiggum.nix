{
  lib,
  stdenv,
  fetchFromGitHub,
  bun,
  makeBinaryWrapper,
}:
stdenv.mkDerivation (_: {
  pname = "open-ralph-wiggum";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "Th0rgal";
    repo = "open-ralph-wiggum";
    rev = "ec503200adf05ccd6b39ddd0fd18f666f595b085";
    hash = "sha256-vTydK3Y0Rj01sp0zCfLoIYSLzQWw+vC2bvVx2/GybWk=";
  };

  nativeBuildInputs = [makeBinaryWrapper];

  # No build step needed — bun runs the TypeScript source directly at runtime.
  # Only dev dependencies (@types/bun) exist; no npm install required.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # Install the TypeScript sources into a libexec directory
    mkdir -p $out/libexec/ralph
    install -Dm644 ralph.ts     $out/libexec/ralph/ralph.ts
    install -Dm644 completion.ts $out/libexec/ralph/completion.ts

    # Create a wrapper that invokes bun with the installed source
    makeBinaryWrapper ${bun}/bin/bun $out/bin/ralph \
      --add-flags "$out/libexec/ralph/ralph.ts"

    runHook postInstall
  '';

  meta = {
    description = "Autonomous agentic loop for Claude Code, Codex, Copilot CLI and OpenCode";
    homepage = "https://github.com/Th0rgal/open-ralph-wiggum";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "ralph";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
