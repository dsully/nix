{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "8b57533efb3a1e6f8295756cb3b12625dae76215";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-OJoiO52X524vssPU8GVU7lZccFDj7klaqnymxQnvh3Y=";
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
