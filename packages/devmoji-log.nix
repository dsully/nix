{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libgit2,
  zlib,
}:
rustPlatform.buildRustPackage rec {
  pname = "devmoji-log";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = pname;
    rev = "7442d75f06e3dc9160ce2dbc6dcf6ca295aeb1f6";
    hash = "sha256-ZKgdvE9eH315WOM89VK/aRKg72ALScmSGBeab5pn554=";
  };

  cargoHash = "sha256-rmV7VJL+Sd3u+rKTwLE42MnCD1sC1W0jeHAlsIvOrQo=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libgit2
    zlib
  ];

  meta = {
    description = "Display Git commit history with conventional commit types and gitmojis";
    homepage = "https://github.com/dsully/devmoji-log";
    license = lib.licenses.mit;
    maintainers = ["dsully"];
    mainProgram = pname;
  };
}
