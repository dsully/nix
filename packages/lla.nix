{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeBinaryWrapper,
  installShellFiles,
  pkg-config,
  oniguruma,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lla";
  version = "0.6.6";

  src = fetchFromGitHub {
    owner = "chaqchase";
    repo = "lla";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zLPAEaRQhh0BIVfasGz7kATQdZrvP6spdMh54+ZY8+A=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    installShellFiles
    pkg-config
  ];

  buildInputs = [oniguruma];

  env.RUSTONIG_SYSTEM_LIBONIG = true;

  cargoHash = "sha256-3utHmX52WIPDWM/T76zi15UhwHczBwgIPAg8tO10M2Y=";
  cargoBuildFlags = ["--workspace"];
  doCheck = false;

  postInstall = ''
    installShellCompletion completions/{_lla,lla{.bash,.fish}}
  '';

  postFixup = ''
    wrapProgram $out/bin/lla \
      --add-flags "--plugins-dir $out/lib"
  '';

  passthru.updateScript = nix-update-script {};

  meta = {
    description = "Blazing-fast `ls` replacement with superpowers";
    homepage = "https://lla.chaqchase.com";
    license = lib.licenses.mit;
    mainProgram = "lla";
  };
})
