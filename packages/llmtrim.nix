{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  libiconv,
  nix-update-script,
}: let
  # The Tauri tray is excluded from the workspace default-members and never goes
  # to crates.io (publish = false). It rides the prebuilt channels, so its
  # committed dist/ is embedded at compile time and no Node step is needed —
  # `cargo build -p llmtrim-tray` just embeds ./dist. Build it only on macOS,
  # where WKWebView ships with the OS; a Linux tray would additionally need
  # webkitgtk + appindicator.
  buildTray = stdenv.hostPlatform.isDarwin;
in
  rustPlatform.buildRustPackage (finalAttrs: {
    pname = "llmtrim";
    version = "0.13.2";
    __structuredAttrs = true;

    src = fetchFromGitHub {
      owner = "fkiene";
      repo = "llmtrim";
      rev = "e4b6f0384de95eec3111a307763c626934be5cdc";
      hash = "sha256-YGJNXsoBnn5Za1zaa3PV9ep7S2kQ6xvhPvE8DVxwiIU=";
    };

    cargoHash = "sha256-nwD8zDFUT2zmoFNVTAZHu6ELXBIHDC1CIwjTupofJg0=";
    doCheck = false;

    # Fix agent fingerprinting: the claude-code marker was the bare substring
    # "Claude Code", which opencode's injected skill descriptions mention, so
    # opencode sessions were mislabeled `claude-code` in `llmtrim status`.
    # Anchor on Claude Code's identity phrase ("You are Claude Code"). Drop once
    # upstream ships an equivalent fix.
    patches = [./llmtrim-claude-code-marker.patch];

    # buildRustPackage builds the workspace default-members, which omit the tray.
    # Name both crates so the CLI and the tray land in $out/bin together.
    cargoBuildFlags =
      [
        "-p"
        "llmtrim"
      ]
      ++ lib.optionals buildTray [
        "-p"
        "llmtrim-tray"
      ];

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = lib.optionals buildTray [
      libiconv
    ];

    passthru.updateScript = nix-update-script {};

    meta = {
      description = "Static, deterministic LLM prompt/payload compressor — cut input tokens 30-90% with zero extra model calls";
      homepage = "https://github.com/fkiene/llmtrim";
      license = lib.licenses.mpl20;
      mainProgram = finalAttrs.pname;
    };
  })
