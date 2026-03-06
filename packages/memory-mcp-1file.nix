{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "memory-mcp-1file";
    rev = "bff9dfceff21a99e62fa126346796bbf47835b56";
    version = "0.8.2";

    src = pkgs.fetchFromGitHub {
      inherit rev;
      owner = "pomazanbohdan";
      repo = "memory-mcp-1file";
      hash = "sha256-5HFCPxk4pNbCuPjuMLU1fw9bwZHik5VxgCkT74sj648=";
    };

    cargoHash = "sha256-0BYtN4rGaSxukauNNGDoXlnN/ziDfpvZK//K6R8GMVM=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      oniguruma
    ];

    env = {
      RUSTONIG_SYSTEM_LIBONIG = true;
    };

    meta = {
      description = "A high-performance, pure Rust Model Context Protocol (MCP) server that provides persistent, semantic, and graph-based memory for AI agents";
      homepage = "https://github.com/pomazanbohdan/memory-mcp-1file";
      maintainers = with lib.maintainers; [dsully];
      mainProgram = "memory-mcp";
    };
  }
