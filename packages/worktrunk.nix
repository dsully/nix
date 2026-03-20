{
  lib,
  rustPlatform,
  fetchCrate,
}:
rustPlatform.buildRustPackage rec {
  pname = "worktrunk";
  version = "0.30.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-VNMaQhSslD37ryx8Q/9lQjXXKHycudgszyS9vyHnxhM=";
  };

  cargoHash = "sha256-khonALVYSkIokG6EGXjJFPwynIYi0d987GwoSVsZ54g=";
  doCheck = false;

  meta = {
    description = "";
    homepage = "https://crates.io/crates/worktrunk";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
