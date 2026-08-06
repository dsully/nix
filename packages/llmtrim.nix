{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "llmtrim";
  version = "0.12.5";
  __structuredAttrs = true;

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-2rVe3ilIyzdxBPFDmg5TciS+dH5GnMUG6NZXsTM6Koo=";
  };

  cargoHash = "sha256-ckamaoalEuDocuYzsgXaCUiXW1pQ0YQNigejnSMU+YU=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Static, deterministic LLM prompt/payload compressor — cut input tokens 30-90% with zero extra model calls";
    homepage = "https://crates.io/crates/llmtrim";
    license = lib.licenses.mpl20;
    mainProgram = pname;
  };
})
