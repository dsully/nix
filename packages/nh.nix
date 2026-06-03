{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "nh";
  rev = "560f86c34e9ab801bf06f39f68ae556fc86194c4";
  version = "4.3.2-${rev}";

  src = fetchFromGitHub {
    owner = "nix-community";
    repo = "nh";
    inherit rev;
    hash = "sha256-P4jmeSW4UGDlE1wyXEFcrRTQze1lQcT1W3dx6lhwq0g=";
  };

  cargoHash = "sha256-NQ5vXOVGHeAOuAl+2x1quh6gwFxbViJpiIr2/lvKPF0=";
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
