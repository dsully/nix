{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "lolcate-rs";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "81ec00ef2d52cf40dd24bbfb47b138f2f558b2d5";
    hash = "sha256-1mq+zQBIwMos2d8wUAr0x7Jz3e40JAlZoLbO3s/lvEw=";
  };

  cargoHash = "sha256-AfIV3dNpQO21b7Ov+BjsbjLN9N2bhsLyi94humR54yg=";
  doCheck = false;

  meta = {
    description = "Lolcate -- A comically fast way of indexing and querying your filesystem. Replaces locate / mlocate / updatedb. Written in Rust";
    homepage = "https://github.com/dsully/lolcate-rs";
    license = lib.licenses.gpl3Only;
    maintainers = ["dsully"];
    mainProgram = "lolcate";
  };
}
