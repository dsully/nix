{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "mdterm";
  version = "2.0.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-tbNE2XjOWeRJmIv6novNOg0kJX2s9TV6Ea5WzhxdDMQ=";
  };

  cargoHash = "sha256-YUPKUFfbzL/1peXEAX5EDehWq4hFwxJLkP2DBDkY23E=";

  meta = {
    description = "A terminal-based Markdown viewer with syntax highlighting and interactive navigation";
    homepage = "https://crates.io/crates/mdterm";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [dsully];
    mainProgram = pname;
  };
}
