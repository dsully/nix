{pkgs, ...}: let
  zig_hook = pkgs.zig_0_14.hook.overrideAttrs {
    zig_default_flags = "-Dcpu=baseline -Doptimize=Debug --color off";
  };
in
  with pkgs;
    stdenvNoCC.mkDerivation {
      pname = "ghostty-ls";
      version = "5969d3a";

      src = fetchFromGitHub {
        owner = "MKindberg";
        repo = "ghostty-ls";
        rev = "5969d3a70833e23243ebf3a993669e7153c0d617";
        hash = "sha256-IHfWtuus38Uw/IlDoiuyt72TEGpMTFAWs/AL2CdjyT8=";
      };

      postPatch = ''
        ln -s ${callPackage ././build.zig.zon.nix {}} "$ZIG_GLOBAL_CACHE_DIR/p"
      '';

      nativeBuildInputs = [
        zig_hook
        makeWrapper
      ];

      meta = {
        description = "A language server for working with the ghostty config";
        homepage = "https://github.com/MKindberg/ghostty-ls";
        license = lib.licenses.mit;
        mainProgram = "ghostty-ls";
        inherit (zig_0_14.meta) platforms;
      };
    }
