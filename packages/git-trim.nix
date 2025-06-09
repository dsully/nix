{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "git-trim";
    version = "unstable-2025-02-18";

    src = fetchFromGitHub {
      owner = "foriequal0";
      repo = "git-trim";
      rev = "07c2f508308a4a59dfb333969518d02f8e328983";
      hash = "sha256-HAj5Ss8tSlc2wXvNIG9+I4wFMPr/Kf06zHyvWeFF7Ac=";
    };

    cargoHash = "sha256-XNL1TYVRnp5jzAMD9hNrjoYnRhoSfU6tD8sm7ZjR1jo=";
    useFetchCargoVendor = true;
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
      description = "Automatically trims your branches whose tracking remote refs are merged or stray";
      homepage = "https://github.com/foriequal0/git-trim";
      license = lib.licenses.mit;
      mainProgram = "git-trim";
    };
  }
