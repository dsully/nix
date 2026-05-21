{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "329b61bba6dd93fddc891a97af12848a67df71c9";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-Ypi4yjeqL/TOXCV8SV2od13Mq10DEhmzY81kU4280wA=";
  };

  cargoHash = "sha256-u9ki037NWMJrd+SJzlWdrmrsFRG3fQ5up0+9qzApH40=";
  doCheck = false;

  postInstall = ''
    rm $out/bin/xtask
  '';

  meta = {
    description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf, @faukah";
    homepage = "https://github.com/nix-community/nh";
    changelog = "https://github.com/nix-community/nh/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = lib.licenses.eupl12;
    mainProgram = pname;
  };
})
