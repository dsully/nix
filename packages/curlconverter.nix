{pkgs, ...}:
with pkgs;
  buildNpmPackage {
    pname = "curlconverter";
    version = "4.12.0";

    src = fetchFromGitHub {
      owner = "curlconverter";
      repo = "curlconverter";
      rev = "b454b1c4f2ad5580750ad2210a67143774a05005";
      hash = "sha256-egYASuVlt0sZaXNNdUcUC+DcJLguHjDl20AszHi+qow=";
    };

    # Patch package.json to remove tree-sitter-cli and modify prepare script
    postPatch = ''
      ${pkgs.jq}/bin/jq '.devDependencies |= del(."tree-sitter-cli") |
        .scripts.prepare = "npm run compile"' \
        package.json > package.json.tmp
      mv package.json.tmp package.json
    '';

    # Override the npm build command since this package uses "compile" not "build"
    npmBuildScript = "compile";

    npmDepsHash = "sha256-UIbMvw8hkZxtSGInV2+Fjm4DZahrdGtSxi0Unhb5lh8=";
    NODE_OPTIONS = "--openssl-legacy-provider";

    meta = {
      description = "Transpile curl commands into Python, JavaScript and 27 other languages";
      homepage = "https://github.com/curlconverter/curlconverter";
      license = lib.licenses.mit;
      mainProgram = "curlconverter";
      platforms = lib.platforms.all;
    };
  }
