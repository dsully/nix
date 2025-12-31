{
  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  inputs = {
    # https://docs.determinate.systems/flakehub/concepts/semver/
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.1";
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

    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";

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
