{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "ea20c2268a29b2cba47fff93a5c5c327b739aa0a";
    pname = "geil";
    version = "0.0.1-alpha.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Nukesor";
      repo = pname;
      hash = "sha256-rlf/bng+pCbqA+iYlnUysKvBHmguzMUyGwZhvhmsWGk=";
    };

    cargoHash = "sha256-8SpF3VcfKNEr3gnQgn5VFe6sRclPwtQAOBB0giF6MnQ=";
    doCheck = false;

    meta = {
      description = "Rocket: A tool to update your repositories and for keeping them clean";
      homepage = "https://github.com/Nukesor/geil";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
