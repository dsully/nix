# Overlays applied to this flake's perSystem package set (see flake.nix), which
# flows to home-manager, nix-darwin, system-manager, and the packages/ builds.
{inputs}: [
  inputs.llm-agents.overlays.shared-nixpkgs

  # Not final.lixPackageSet.<tool>: that set takes these tools from final and would recurse.
  (final: prev: let
    nix = final.lixPackageSet.lix;
  in {
    lixPackageSet = prev.lixPackageSets.lix_2_96;
    nix-direnv = prev.nix-direnv.override {inherit nix;};
    nix-init = prev.nix-init.override {inherit nix;};
    nixos-option = prev.nixos-option.override {inherit nix;};
    nurl = prev.nurl.override {inherit nix;};
  })

  # cargo-setup-hook's cargoUseSystemLibs forces system C libs these packages don't declare.
  (_: prev:
    prev.lib.genAttrs ["cargo-clone" "samply" "syswatch" "ttl"] (name:
      prev.${name}.overrideAttrs {dontCargoUseSystemLibs = true;}))
]
