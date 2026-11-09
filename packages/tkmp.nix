{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "tkmp";
  version = "0-unstable-2026-10-30";

  src = fetchFromGitHub {
    owner = "tfcace";
    repo = "tkmp";
    rev = "1c7cb9942da839f3b06de320429b45345989a5a5";
    hash = "sha256-KQOg/4tJ9iynXCGnwNbZuIhqpkcfUonjgoxtRtpi/aw=";
  };

  cargoHash = "sha256-kpLz9KOYtVp9flgL7aUnyQYGTe1LUorG1HYgFt0d1Jc=";
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Live markdown previewer for Rex: Mermaid diagrams and big-type headings over the kitty graphics protocol";
    homepage = "https://github.com/tfcace/tkmp";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
