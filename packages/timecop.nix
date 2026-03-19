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
    rev = "36d1d6a7efe5e94ca041c1db86602bbc66aaee21";
    hash = "sha256-AV8oFnXhNHhestWlGxfUymle+iD5Gf+cJN9IXW58V0Y=";
  };

  cargoHash = "sha256-kY3sNLlLqqgFsfngAaLEev1b0GPCAPU/mGkCTyUMu8A=";
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
