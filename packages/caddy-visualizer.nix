{
  buildNpmPackage,
  fetchFromGitHub,
  geist-font,
  inter,
  lib,
  makeWrapper,
  nodejs_24,
  python3,
}:
buildNpmPackage rec {
  pname = "caddy-visualizer";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "dree007";
    repo = "caddy-visualizer";
    tag = "v${version}";
    hash = "sha256-Mm9pRO7OEAHC+iWdkHJZ3jYtJQVQRok5ECmu44HFWtw=";
  };

  npmDepsHash = "sha256-iVJ2UF66zK39HsNdh8ZLFZ7LB0PTVaLn+7TUIS+C4G8=";
  nodejs = nodejs_24;

  nativeBuildInputs = [makeWrapper python3];

  env.NEXT_TELEMETRY_DISABLED = "1";

  # next/font/google downloads at build time; the sandbox has no network. Inter
  # Tight is not in nixpkgs, so the display face falls back to Inter.
  postPatch = ''
    mkdir -p src/app/fonts
    cp ${inter}/share/fonts/truetype/InterVariable.ttf src/app/fonts/
    cp '${geist-font}/share/fonts/truetype/GeistMono[wght].ttf' src/app/fonts/GeistMono.ttf
    substituteInPlace src/app/layout.tsx \
      --replace-fail 'import { Geist_Mono, Inter, Inter_Tight } from "next/font/google";' 'import localFont from "next/font/local";' \
      --replace-fail 'Inter({ subsets: ["latin"], variable' 'localFont({ src: "./fonts/InterVariable.ttf", variable' \
      --replace-fail 'Inter_Tight({' 'localFont({ src: "./fonts/InterVariable.ttf",' \
      --replace-fail 'Geist_Mono({' 'localFont({ src: "./fonts/GeistMono.ttf",' \
      --replace-fail 'subsets: ["latin"],' "" \
      --replace-fail 'weight: ["300", "400"],' ""
  '';

  installPhase = ''
    runHook preInstall

    app=$out/share/caddy-visualizer
    mkdir -p $app/.next
    cp -r .next/standalone/. $app/
    cp -r .next/static $app/.next/static
    cp -r public drizzle $app/

    # Migrations are read from ./drizzle relative to the working directory.
    makeWrapper ${lib.getExe nodejs_24} $out/bin/caddy-visualizer \
      --chdir $app \
      --set-default NODE_ENV production \
      --set-default NEXT_TELEMETRY_DISABLED 1 \
      --add-flags $app/server.js

    runHook postInstall
  '';

  meta = {
    description = "Web UI for a Caddy server: Caddyfile editor, sites, metrics and logs";
    homepage = "https://github.com/dree007/caddy-visualizer";
    license = lib.licenses.mit;
    mainProgram = "caddy-visualizer";
    platforms = lib.platforms.linux;
  };
}
