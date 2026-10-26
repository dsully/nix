{
  stdenv,
  requireFile,
}:
stdenv.mkDerivation rec {
  pname = "apple-notes-editor";
  version = "0.1.0";

  # Private release assets need a GitHub token, which Nix fetchers cannot send.
  src = requireFile {
    name = "${pname}-aarch64-apple-darwin.tar.gz";
    url = "https://github.com/dsully/${pname}/releases/tag/v${version}";
    hash = "sha256-BOKiNA5kMxTH9MgRiA+335ZPppovMh8k4Bk5b55izTw=";
    message = ''
      Add the private release asset to the store using "just install" in the repo.
    '';
  };

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -m755 -D ${pname} $out/bin/${pname}

    runHook postInstall
  '';

  meta = {
    description = "List, read and rewrite Apple Notes as Markdown from an editor";
    homepage = "https://github.com/dsully/apple-notes-editor";
    mainProgram = pname;
    platforms = ["aarch64-darwin"];
  };
}
