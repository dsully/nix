{
  config,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  c = config.colors;
  hex = s: "hex:${c.noHash s}";
in {
  xdg.configFile."ccstatusline/settings.json".source = jsonFormat.generate "settings.json" {
    colorLevel = 3;
    compactThreshold = 60;
    defaultPadding = " ";
    flexMode = "full-minus-40";
    globalBold = false;
    inheritSeparatorColors = false;
    lines = [
      [
        {
          id = "1";
          type = "model";
          color = hex c.black.dim;
          backgroundColor = hex c.cyan.bright;
        }
        {
          id = "29ec0538-f1a2-4570-bf25-8de0e1af0e23";
          type = "context-percentage";
          color = hex c.white.dim;
          backgroundColor = hex c.gray.base;
        }
        {
          id = "3";
          type = "context-length";
          color = hex c.white.dim;
          backgroundColor = hex c.blue.base;
        }
        {
          id = "5";
          type = "git-branch";
          color = hex c.black.dim;
          backgroundColor = hex c.green.base;
        }
      ]
      []
      []
    ];
    powerline = {
      autoAlign = true;
      enabled = true;
      endCaps = [];
      separatorInvertBackground = [false];
      separators = [""];
      startCaps = [];
      theme = "nord";
    };
    version = 3;
  };
}
