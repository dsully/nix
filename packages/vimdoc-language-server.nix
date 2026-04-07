{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "vimdoc-language-server";
  version = "0.2.0";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-V70J5Z4hOhhdUbuyl9Fsj1JULCJHLO2+6uFUI7N/Wxk=";
  };

  cargoHash = "sha256-gMQhtSWhh3noeCN7SsIntQ+Fus5bfxg4DmJh7h3VWuA=";

  meta = {
    description = "Language server for vim help files";
    homepage = "https://crates.io/crates/vimdoc-language-server";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
})
