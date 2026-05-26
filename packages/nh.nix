{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "976aaa8ee7de7a042b4b88045db0708bd2da1ec0";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-aoDYNvP6VZRr0XHCADKa1ovFWan+pCl0UQGT3V4QeT4=";
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
