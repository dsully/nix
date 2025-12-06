{
  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    mcp-servers-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-ai-tools.url = "github:numtide/nix-ai-tools";
    nix-ai-tools.inputs.nixpkgs.follows = "nixpkgs";

    config-lsp.url = "github:Myzel394/config-lsp";
    config-lsp.inputs.nixpkgs.follows = "nixpkgs";

    charmbracelet-nur.url = "github:charmbracelet/nur";
    charmbracelet-nur.inputs.nixpkgs.follows = "nixpkgs";

    opnix.url = "github:brizzbuzz/opnix";

    crane.url = "github:ipetkov/crane";

    ai-skills-ast-grep.url = "github:ast-grep/claude-skill";
    ai-skills-ast-grep.flake = false;
  };

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    };
}
