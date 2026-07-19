# Overlays applied to this flake's perSystem package set (see flake.nix), which
# flows to home-manager, nix-darwin, system-manager, and the packages/ builds.
{inputs}: [
  # numtide llm-agents — exposes pkgs.llm-agents.* built against our nixpkgs
  # (byte-identical store paths to inputs.llm-agents.packages, so cache hits are
  # preserved).
  inputs.llm-agents.overlays.shared-nixpkgs

  # Local nixpkgs fixes. Future python3Packages.* test fixes belong in a
  # pythonPackagesExtensions entry here; mcp-nixos below is a top-level
  # buildPythonApplication (not a python3Packages member), so it's overridden
  # directly.
  (_final: prev: {
    # mcp-nixos' upstream test suite (tests/test_store.py) scans /nix/store for
    # an arbitrary text file and asserts "Error" is absent — nondeterministic in
    # the build sandbox. On PATH so per-repo .mcp.json / opencode.jsonc can
    # launch it.
    mcp-nixos = prev.mcp-nixos.overridePythonAttrs (_: {doCheck = false;});
  })
]
