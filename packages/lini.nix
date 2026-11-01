{
  lib,
  rustPlatform,
  fetchCrate,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "lini";
  version = "1.1.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-7sYPGN2VMNp7bhQSL292VUoq7OPxXXx81+zAZjq1UyI=";
  };

  cargoHash = "sha256-8Z0dptp6tnqHt+OBSML1OBH7OUiO+V2oQuxlhgVgxdQ=";
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Mermaid-like SVG Language Generator";
    homepage = "https://crates.io/crates/lini";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
