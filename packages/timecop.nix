{
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  openssl,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "timecop";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "kamilmac";
    repo = "timecop";
    rev = "b649cfe4715208bb5ff046bbc571b9681bb55e8d";
    hash = "sha256-KskABgTV7gCHfBA0tzK8iCctFKiqDvvtuARSIVXerTk=";
  };

  cargoHash = "sha256-s+XIbw0JOJCsrDBx2BwXR70Qf5Lx3HsEhzNxK1yddZY=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    openssl
    zlib
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
  };

  meta = {
    description = "";
    homepage = "https://github.com/kamilmac/timecop";
    mainProgram = pname;
  };
}
