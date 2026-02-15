{
  config,
  lib,
  ...
}: let
  c = config.colors;

  # KDL DSL helpers — zellij's config uses KDL, and home-manager's toKDL generator
  # uses _args for positional arguments and _children for nested nodes.

  # bind ["key1" "key2"] [action1 action2] → bind "key1" "key2" { action1; action2; }
  bind = keys: actions: {
    bind = {
      _args = keys;
      _children = actions;
    };
  };

  # mode "Foo" → SwitchToMode "Foo"
  mode = m: {
    SwitchToMode = {
      _args = [m];
    };
  };

  # act "Quit" → Quit { }  (action with no arguments)
  act = name: {${name} = {};};

  # act1 "MoveFocus" "Left" → MoveFocus "Left"  (action with one argument)
  act1 = name: arg: {
    ${name} = {
      _args = [arg];
    };
  };

  normal = mode "Normal";

  # modeBinds "tab" [...] → tab { ... }  (keybind block for a mode)
  modeBinds = name: binds: {${name}._children = binds;};

  # goTab 3 → bind "3" { GoToTab 3; SwitchToMode "Normal"; }
  goTab = n: bind ["${toString n}"] [(act1 "GoToTab" n) normal];

  # sharedExcept ["locked" "normal"] → shared_except "locked" "normal"
  sharedExcept = modes: let
    quoted = lib.concatMapStringsSep " " (m: ''"${m}"'') modes;
  in "shared_except ${quoted}";
in {
  programs.zellij = {
    enable = true;
    enableFishIntegration = false;

    settings = {
      keybinds = {
        _props.clear-defaults = true;
        _children = [
          {
            unbind = [
              "Ctrl b"
              "Ctrl g"
            ];
          }

          (modeBinds "normal" [
            (bind ["Super c"] [(act "Copy")])
            (bind ["Super Alt Left"] [(act "GoToPreviousTab")])
            (bind ["Super Alt Right"] [(act "GoToNextTab")])
            (bind ["Super w"] [(act "CloseTab")])
            (bind ["Super n"] [(act "NewTab")])
          ])

          (modeBinds "locked" [
            (bind ["Ctrl g"] [normal])
          ])

          (modeBinds "tab" [
            (bind ["Ctrl t"] [normal])
            (bind ["r"] [(mode "RenameTab") (act1 "TabNameInput" 0)])
            (bind ["h" "Left" "Up" "k" "["] [(act "GoToPreviousTab")])
            (bind ["l" "Right" "Down" "j" "]"] [(act "GoToNextTab")])
            (bind ["c"] [(act "NewTab") normal])
            (bind ["n"] [(act "NewTab") normal])
            (bind ["x"] [(act "CloseTab") normal])
            (bind ["s"] [(act "ToggleActiveSyncTab") normal])
            (goTab 1)
            (goTab 2)
            (goTab 3)
            (goTab 4)
            (goTab 5)
            (goTab 6)
            (goTab 7)
            (goTab 8)
            (goTab 9)
            (bind ["Tab"] [(act "ToggleTab")])
          ])

          (modeBinds "scroll" [
            (bind ["Ctrl s"] [normal])
            (bind ["e"] [(act "EditScrollback") normal])
            (bind ["s"] [(mode "EnterSearch") (act1 "SearchInput" 0)])
            (bind ["Ctrl c"] [(act "ScrollToBottom") normal])
            (bind ["j" "Down"] [(act "ScrollDown")])
            (bind ["k" "Up"] [(act "ScrollUp")])
            (bind ["PageDown" "Right" "l" "Ctrl ]"] [(act "PageScrollDown")])
            (bind ["PageUp" "Left" "h" "Ctrl ["] [(act "PageScrollUp")])
          ])

          (modeBinds "search" [
            (bind ["Ctrl s"] [normal])
            (bind ["Ctrl c"] [(act "ScrollToBottom") normal])
            (bind ["j" "Down"] [(act "ScrollDown")])
            (bind ["k" "Up"] [(act "ScrollUp")])
            (bind ["Ctrl f" "PageDown" "Right" "l"] [(act "PageScrollDown")])
            (bind ["Ctrl b" "PageUp" "Left" "h"] [(act "PageScrollUp")])
            (bind ["d"] [(act "HalfPageScrollDown")])
            (bind ["u"] [(act "HalfPageScrollUp")])
            (bind ["n"] [(act1 "Search" "down")])
            (bind ["p"] [(act1 "Search" "up")])
            (bind ["c"] [(act1 "SearchToggleOption" "CaseSensitivity")])
            (bind ["w"] [(act1 "SearchToggleOption" "Wrap")])
            (bind ["o"] [(act1 "SearchToggleOption" "WholeWord")])
          ])

          (modeBinds "entersearch" [
            (bind ["Ctrl c" "Esc"] [(mode "Scroll")])
            (bind ["Enter"] [(mode "Search")])
          ])

          (modeBinds "pane" [
            (bind ["Ctrl p"] [normal])
            (bind ["h" "Left"] [(act1 "MoveFocus" "Left")])
            (bind ["l" "Right"] [(act1 "MoveFocus" "Right")])
            (bind ["j" "Down"] [(act1 "MoveFocus" "Down")])
            (bind ["k" "Up"] [(act1 "MoveFocus" "Up")])
            (bind ["p"] [(act "SwitchFocus")])
            (bind ["n"] [(act "NewPane") normal])
            (bind ["d"] [(act1 "NewPane" "Down") normal])
            (bind ["r"] [(act1 "NewPane" "Right") normal])
            (bind ["x"] [(act "CloseFocus") normal])
            (bind ["f"] [(act "ToggleFocusFullscreen") normal])
            (bind ["z"] [(act "TogglePaneFrames") normal])
            (bind ["w"] [(act "ToggleFloatingPanes") normal])
            (bind ["e"] [(act "TogglePaneEmbedOrFloating") normal])
            (bind ["c"] [(mode "RenamePane") (act1 "PaneNameInput" 0)])
          ])

          (modeBinds "renametab" [
            (bind ["Ctrl c"] [normal])
            (bind ["Esc"] [(act "UndoRenameTab") (mode "Tab")])
          ])

          (modeBinds "session" [
            (bind ["Ctrl S"] [normal])
            (bind ["Ctrl s"] [(mode "Scroll")])
            (bind ["d"] [(act "Detach")])
            (
              bind
              ["w"]
              [
                {
                  LaunchOrFocusPlugin = {
                    _args = ["zellij:session-manager"];
                    floating = true;
                    move_to_focused_tab = true;
                  };
                }
                normal
              ]
            )
          ])

          (modeBinds (sharedExcept ["locked"]) [
            (bind ["Ctrl q"] [(act "Quit")])
            (bind ["Alt n"] [(act "NewPane")])
          ])

          (
            modeBinds
            (sharedExcept [
              "normal"
              "locked"
            ])
            [
              (bind ["Enter" "Esc"] [normal])
            ]
          )

          (
            modeBinds
            (sharedExcept [
              "pane"
              "locked"
            ])
            [
              (bind ["Ctrl p"] [(mode "Pane")])
            ]
          )

          (
            modeBinds
            (sharedExcept [
              "scroll"
              "locked"
            ])
            [
              (bind ["Ctrl s"] [(mode "Scroll")])
            ]
          )

          (
            modeBinds
            (sharedExcept [
              "session"
              "locked"
            ])
            [
              (bind ["Ctrl S"] [(mode "Session")])
            ]
          )

          (
            modeBinds
            (sharedExcept [
              "tab"
              "locked"
            ])
            [
              (bind ["Ctrl t"] [(mode "Tab")])
            ]
          )
        ];
      };

      plugins = {
        tab-bar._props.path = "tab-bar";
        status-bar._props.path = "status-bar";
        strider._props.path = "strider";
        compact-bar._props.path = "compact-bar";
        session-manager._props.path = "session-manager";
      };

      on_force_close = "detach";
      default_shell = "fish";
      pane_frames = true;
      theme = "dsully";
      default_layout = "compact-borderless";
      mouse_mode = false;
      scroll_buffer_size = 50000;
      default_cwd = "";
      serialize_pane_viewport = true;
    };

    themes.dsully = ''
      themes {
          dsully {
              fg "${c.white.dim}"
              bg "${c.black.dim}"
              black "${c.black.base}"
              red "${c.red.base}"
              green "${c.blue.base}"
              yellow "${c.yellow.base}"
              blue "${c.blue.base}"
              magenta "${c.magenta.base}"
              cyan "${c.cyan.bright}"
              white "${c.white.base}"
              orange "${c.orange.base}"
          }
      }
    '';

    layouts.compact-borderless = ''
      layout {
          pane borderless=true
          pane size=1 borderless=true {
              plugin location="zellij:compact-bar"
          }
      }
    '';
  };
}
