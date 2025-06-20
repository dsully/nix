{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.10";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "459ba700e2a396d9bcd384f5c7ffbe9aae9b2e8f";
      hash = "sha256-kh39BCKTDwYoijvT+VkWowawPsuF0E4o+buP1Invfe4=";
    };

    cargoHash = "sha256-y2pwEu006PsVmJKesAD/UDDbhdNre79AKZRAmFEZVDQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    meta = {
      description = "TOML Formatter / Linter / Language Server";
      homepage = "https://github.com/tombi-toml/tombi";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
