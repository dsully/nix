{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "mcp-git-tools";
    rev = "ce1501a504c8cb3541c6d176109a43ade12ea4fa";
    version = "0.2.0";

    src = fetchFromGitHub {
      inherit rev;
      owner = "lileeei";
      repo = "mcp-git-tools";
      hash = "sha256-bFUytfhz1dxFzLjd+1WmUQ3c7W3pH8rPIb30/B4rYF4=";
    };

    cargoHash = "sha256-CuCDUwAvC1n5rf1+VcuS1DfHfj14z+7ZqKQo1QiJw/w=";
    doCheck = false;

    meta = {
      description = "Git tool integration library for the Model Context Protocol (MCP";
      homepage = "https://github.com/lileeei/mcp-git-tools";
      license = lib.licenses.mit;
      mainProgram = "mcp-git-server";
    };
  }
