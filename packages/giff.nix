{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "giff";
  version = "1.1.0";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-ivTkvQpq3aFrBGK53OlO+DpfXUAQ3yLCFMH27akGZEk=";
  };

  cargoHash = "sha256-IjXdWp5LdxIxfj2NL1EdxGh29L8Q/ExqX8yNHFStT1M=";

  meta = {
    description = "Visualizes the differences in a git repository";
    homepage = "https://crates.io/crates/giff";
    license = with lib.licenses; [
      mit
      unlicense
    ];
    mainProgram = pname;
  };
})
