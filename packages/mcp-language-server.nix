{pkgs, ...}:
with pkgs;
  buildGoModule rec {
    pname = "mcp-language-server";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "isaacphi";
      repo = "mcp-language-server";
      rev = "e4395849a52e18555361abab60a060802c06bf50";
      hash = "sha256-T0wuPSShJqVW+CcQHQuZnh3JOwqUxAKv1OCHwZMr7KM=";
    };

    vendorHash = "sha256-3NEG9o5AF2ZEFWkA9Gub8vn6DNptN6DwVcn/oR8ujW0=";

    ldflags = ["-s" "-w"];

    meta = {
      description = "Mcp-language-server gives MCP enabled clients access semantic tools like get definition, references, rename, and diagnostics";
      homepage = "https://github.com/isaacphi/mcp-language-server";
      license = lib.licenses.bsd3;
      mainProgram = pname;
    };
  }
