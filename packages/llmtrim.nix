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
    version = "0.13.3";
    __structuredAttrs = true;

    src = fetchFromGitHub {
      owner = "fkiene";
      repo = "llmtrim";
      rev = "0555a6acb9339ce0b88ec13fbfb05ce9a11ceddc";
      hash = "sha256-aeclpcf3O/uFZ3VuR5fVHhJPbAIU1ezWiBl+jLFk13A=";
    };

    cargoHash = "sha256-vmMhWqDvy5Q/2M+A5Ur0jat7zVz1CarGXGu1zVBredo=";
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
