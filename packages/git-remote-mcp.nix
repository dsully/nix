{
  lib,
  openssl,
  pkg-config,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "git-remote-mcp";
  version = "0.1.1";

  src = fetchGit {
    url = "https://github.com/dsully/git-remote-mcp";
    rev = "d09a1e47a9853d8d77ba1852f855c0b6d1ff2ffc";
  };

  cargoHash = "sha256-NhgxZQiQgIq57tIy52kAe608utbTfFxV5RtatCAJ7AQ=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ];

  meta = {
    description = "A high-performance Model Context Protocol (MCP) server written in Rust.";
    homepage = "https://github.com/dsully/git-remote-mcp";
    license = lib.licenses.mit;
    mainProgram = "git-remote-mcp-server";
  };
}
