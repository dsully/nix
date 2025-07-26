{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "7d2036bd6cc62dc4676abeaff57601a39754e8c9";
    pname = "emmylua-analyzer-rust";
    version = "0.9.1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-7fNSCZntEOMv6y18l47ZfHdTNwr0nOmepwGpz81FqkQ=";
    };

    cargoHash = "sha256-MIGYx1qMxsCCq3QkFeOuKbM4w/sJ2K0T+SRIDJQjf/8=";
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
