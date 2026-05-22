{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "444ba5185895f8b0014f387d03c06c00c6831961";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-fSMBlPzWKgkYIgDjD8Fhp46RwNeAFoe575NO4TIgEEk=";
  };

  cargoHash = "sha256-u9ki037NWMJrd+SJzlWdrmrsFRG3fQ5up0+9qzApH40=";
  doCheck = false;

  env.NH_REV = rev;

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
