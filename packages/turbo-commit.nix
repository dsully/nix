{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  openssl,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "turbo-commit";
  rev = "a2e42f571121bb08f793ab3f44048e35910400b2";
  version = "3.0.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "dikkadev";
    repo = "turboCommit";
    hash = "sha256-xb9ZuiYiUstcPrpDRomi1u+Pi/WHHojzIH1yQHkvLkg=";
  };

  cargoHash = "sha256-QRAMM0ZJNo2iD/5+YbmNg2J1EjYtJGaxDtj5gcyTjTE=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    openssl
    zlib
  ];

  meta = {
    description = "Turbocommit is a tool that generates high-quality git commit messages in accordance with the Conventional Commits specification";
    homepage = "https://github.com/dikkadev/turboCommit";
    license = lib.licenses.mit;
    mainProgram = "turbocommit";
  };
}
