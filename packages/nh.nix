{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  rom,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "1516b6370f4013a9a5fb03f1b87ac07c9b5e3642";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-EwPx2oDcxOmwmGeLwRnwybO0a1RQtz24iIIWop16/Ow=";
  };

  cargoHash = "sha256-3t2J4HtKApNdYVQRwAHPErOrYxfJN/YMbenbPd5OnM8=";
  doCheck = false;

  # Make the build output monitor configurable via NH_MONITOR, then default it
  # to rom (a drop-in for nix-output-monitor that reads the same internal-json
  # stream) and keep rom on PATH so the wrapped binary always finds it.
  patches = [./nh-rom.patch];

  nativeBuildInputs = [makeWrapper];

  env.NH_REV = rev;

  postInstall = ''
    rm $out/bin/xtask

    wrapProgram $out/bin/nh \
      --set-default NH_MONITOR rom \
      --prefix PATH : ${lib.makeBinPath [rom]}
  '';

  meta = {
    description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf, @faukah";
    homepage = "https://github.com/nix-community/nh";
    changelog = "https://github.com/nix-community/nh/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.eupl12;
    mainProgram = pname;
  };
})
