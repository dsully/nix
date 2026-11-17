{
  lib,
  rustPlatform,
  fetchCrate,
  nix-update-script,
}:
rustPlatform.buildRustPackage rec {
  pname = "lini";
  version = "1.1.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-wl5ZM2fonqz47Hg2TFHZPVLLhKuF0Q7bJqncVp5tb/s=";
  };

  cargoHash = "sha256-MgSNSz7/sTsGKC9kAELbDaVq6/VOIT1QPv/E9ILoIbQ=";
  doCheck = false;

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Mermaid-like SVG Language Generator";
    homepage = "https://crates.io/crates/lini";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
