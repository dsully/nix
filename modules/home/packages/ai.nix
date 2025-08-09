{
  flake,
  pkgs,
  ...
}: {
  home = {
    packages =
      (with ((flake.inputs.upstream or flake).inputs.nix-ai-tools.packages.${pkgs.system} or {}); [
        claude-code
        crush
        opencode
        gemini-cli
      ])
      ++ (with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {}));
        [
          aichat
        ]
        ++ [
          git-ai-commit
          turbo-commit
        ]);
  };
}
