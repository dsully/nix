{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "mdterm";
  version = "1.5.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-Ds9hlilZClIJQGakpbPESPHfgP8Q3/jzQ0e8k2PQQio=";
  };

  cargoHash = "sha256-vxiDwblpu9Bo5ofXng6tAelRF3zyL65lCD5ztFnFRpU=";

  meta = {
    description = "A terminal-based Markdown viewer with syntax highlighting and interactive navigation";
    homepage = "https://crates.io/crates/mdterm";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [dsully];
    mainProgram = pname;
  };
}
