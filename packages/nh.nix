{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  rom,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "fbdd2c9b8d81d8053b1b4f2dc82bc448a231e1a1";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-qt22yOhP+TXaJ3g6IuVLr6/JPEUVax8+8Wjc9Uekb+0=";
  };

  cargoHash = "sha256-PmaGe5KtyVaavBt9cwdacIocnuv1T7xoHhuTTK87ngc=";
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
