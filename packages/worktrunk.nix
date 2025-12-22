{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.6.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-rFO5EEzTLNnwgrBbzPnOZ5C94EsGMn6g9+GOJkQHyrs=";
    };

    cargoHash = "sha256-Av8CBcd3ffjfTYCoSbyyE9DJ7iZt8MIsH23UA/2jO64=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
