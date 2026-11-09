{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rex-agent-resume";
  version = "0.1.0-beta.5";

  src = fetchFromGitHub {
    owner = "YangJonghun";
    repo = "rex-agent-resume";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ZCloft5ZFVHNRPnkk5z2VeTZB2PpbOu7JDtD44cg4ME=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    root=$out/share/rex-agent-resume
    mkdir -p $root
    cp -R plugin.lua bin lua integrations $root/
    substituteInPlace $root/integrations/pi/rex-agent-resume.ts \
      --replace-fail __REX_AGENT_RESUME_HOOK__ $root/bin/rex-agent-resume-hook

    runHook postInstall
  '';

  meta = {
    description = "Reopen AI agents and tools in their Rex panes after a server restart";
    homepage = "https://github.com/YangJonghun/rex-agent-resume";
    platforms = lib.platforms.unix;
  };
})
