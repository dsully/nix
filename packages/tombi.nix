{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "tombi";
    version = "0.4.10";

    src = fetchFromGitHub {
      owner = "tombi-toml";
      repo = "tombi";
      rev = "d53d28861be737303258bbbccd4f17f83182d3ed";
      hash = "sha256-23dArS+obyQ7yIj4l/fqBfZCAQe0NQl9lGm4FSH/p9c=";
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
