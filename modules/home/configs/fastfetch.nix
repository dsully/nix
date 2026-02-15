{
  programs.fastfetch = {
    enable = false;

    settings = {
      display = {
        separator = " ";
        temp.unit = "FAHRENHEIT";
      };

      modules = [
        "break"
        "break"
        "break"
        {
          type = "host";
          key = "╭─󰌢";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "├─󰻠";
          keyColor = "green";
        }
        {
          type = "battery";
          key = "├─";
          keyColor = "green";
        }
        {
          type = "poweradapter";
          key = "├─";
          keyColor = "green";
        }
        {
          type = "sound";
          key = "├─";
          keyColor = "green";
        }
        {
          type = "custom";
          key = "╰─╯";
          keyColor = "green";
        }
        "break"
        {
          type = "title";
          key = "╭─";
          format = "{1}@{2}";
          keyColor = "blue";
        }
        {
          type = "os";
          key = "├─";
          keyColor = "blue";
        }
        {
          type = "kernel";
          key = "├─";
          format = "{1} {2}";
          keyColor = "blue";
        }
        {
          type = "custom";
          key = "╰─╯";
          keyColor = "blue";
        }
      ];
    };
  };
}
