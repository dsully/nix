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

    nix-index.url = "github:nix-community/nix-index";
    nix-index.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";

    system-manager.url = "github:numtide/system-manager";
    system-manager.inputs.nixpkgs.follows = "nixpkgs";

    nh.url = "github:nix-community/nh";
    nh.inputs.nixpkgs.follows = "nixpkgs";

    bun2nix.url = "github:baileyluTCD/bun2nix";
    bun2nix.inputs.nixpkgs.follows = "nixpkgs";

    emmylua-analyzer-rust.url = "github:EmmyLuaLs/emmylua-analyzer-rust";
    emmylua-analyzer-rust.inputs.nixpkgs.follows = "nixpkgs";

    tombi.url = "github:tombi-toml/tombi";
    tombi.inputs.nixpkgs.follows = "nixpkgs";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";
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
