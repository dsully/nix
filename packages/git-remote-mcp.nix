{
  lib,
  rustPlatform,
  pkg-config,
}:
rustPlatform.buildRustPackage {
  pname = "git-remote-mcp";
  version = "0.1.0";

  src = fetchGit {
    url = "git+ssh://git@github.com/dsully/git-remote-mcp";
    rev = "ff7ae4ddd1d332634d940613e5a4fb97693e4563";
  };

  cargoHash = "sha256-9lxVK1RUDw37FFe9PVQW5cdrmEUq1cwCazLJ0beq3UU=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  meta = {
    description = "A high-performance Model Context Protocol (MCP) server written in Rust.";
    homepage = "https://github.com/dsully/git-remote-mcp";
    license = lib.licenses.mit;
    mainProgram = "git-remote-mcp-server";
  };
}
