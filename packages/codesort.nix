{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "codesort";
    version = "unstable-2025-02-02";

    src = fetchFromGitHub {
      owner = "Canop";
      repo = "codesort";
      rev = "b71c3e05459f20b38019c089c97822da9c2a0cf4";
      hash = "sha256-yi5BjlmRHL3J18dP6le08FYesPalZIzIeMV6znHpafo=";
    };

    cargoHash = "sha256-0EY5e5wu9J2zK3S200DbCv6mOj/7iMJ6aw45e5Fg+go=";
    doCheck = false;

    meta = {
      description = "Codesort sorts code";
      homepage = "https://github.com/Canop/codesort";
      changelog = "https://github.com/Canop/codesort/blob/${src.rev}/CHANGELOG.md";
      mainProgram = pname;
    };
  }
