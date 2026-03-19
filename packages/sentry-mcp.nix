{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "sentry-mcp";
  version = "0.3.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-8A3KJhd6MwNUmtrNJSm1WPZnoc3l/5t27jw1/rpSaKk=";
  };

  cargoHash = "sha256-K9NGFMBLbS9RM6VsgM5SrjbbuMZAruJtl9nEO+3V7ro=";
  doCheck = false;

  meta = {
    description = "A minimal MCP server for Sentry";
    homepage = "https://crates.io/crates/sentry-mcp";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
