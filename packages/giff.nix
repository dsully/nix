{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "giff";
  version = "1.2.0";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-qjJsjL41O4WK8zMJiADd1Kz20jHfg8qQzCdWjAOULgg=";
  };

  cargoHash = "sha256-094QMCEI4ShTqlfYZUxCUUd/Fx9kmATHKuJPKqGxw7s=";

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
