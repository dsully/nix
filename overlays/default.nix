# Overlays applied to this flake's perSystem package set (see flake.nix), which
# flows to home-manager, nix-darwin, system-manager, and the packages/ builds.
{inputs}: [
  inputs.llm-agents.overlays.shared-nixpkgs
]
