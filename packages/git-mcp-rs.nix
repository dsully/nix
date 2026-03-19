{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "git-mcp-rs";
  rev = "ea7352a5b4997c1521d0eb86df9ebfcd66e47e89";
  version = "0.2.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "HanSoBored";
    repo = "git-mcp-rs";
    hash = "sha256-JsRVRLOP+346sEs4MtHXQX7p7eVX4cq78WfY8BBvFZw=";
  };

  cargoHash = "sha256-suW9mB1/oSIaPV8/hez/7MRWmJjcFPd61ZwWOYJ9KXM=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
  };

  meta = {
    description = "A high-performance Model Context Protocol (MCP) server written in Rust.";
    homepage = "https://github.com/HanSoBored/git-mcp-rs";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [dsully];
    mainProgram = "git_mcp";
  };
}
