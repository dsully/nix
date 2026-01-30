{pkgs, ...}: let
  jsonFormat = pkgs.formats.json {};
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
          color = "hex:2E3440";
          backgroundColor = "hex:88C0D0";
        }
        {
          id = "29ec0538-f1a2-4570-bf25-8de0e1af0e23";
          type = "context-percentage";
          color = "hex:D8DEE9";
          backgroundColor = "hex:4C566A";
        }
        {
          id = "3";
          type = "context-length";
          color = "hex:FDF6E3";
          backgroundColor = "hex:83a1c1";
        }
        {
          id = "5";
          type = "git-branch";
          color = "hex:2E3440";
          backgroundColor = "hex:#a3be8c";
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
