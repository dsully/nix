{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "5cffbb2fbebab62811b65c2e867667cf71bf7922";
      hash = "sha256-fmQBZfbKBo+JGI/XsLhBP9U0yK9AqvZPoTmSJbQXz2w=";
    };

    cargoHash = "sha256-I5h63A8hAmeQfy0E7zNm91YEUxa7iLNR3o4yMLpvdd4=";
    useFetchCargoVendor = true;
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
