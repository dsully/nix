{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "vimdoc-language-server";
  version = "0.1.1";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-XAWOaovU3SYyZXa0aex2viIntKlDIUcIKGapIeYqJnw=";
  };

  cargoHash = "sha256-kpfvUlOg/dQSh9vej9Mm5qDzKYI8RLap/vUdkq7Bd6s=";

  meta = {
    description = "Language server for vim help files";
    homepage = "https://crates.io/crates/vimdoc-language-server";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
})
