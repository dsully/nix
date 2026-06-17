{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  rom,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "6a69a6521afb64e5f74475ff059a93d71138a46a";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-G+swQrozQ9GYv7b+UUJbprKWDgX+iDmDYzJ/8UHJBXE=";
  };

  cargoHash = "sha256-mjLj+pLC5yccTPl/DqqyGdMqIus8FNphamcVZ6AkmOw=";
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
