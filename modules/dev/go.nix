{
  mkUserModule,
  config,
  ...
}: let
  goPath = "${config.xdg.dataHome}/go";
in
  mkUserModule {
    name = "go";

    home = {
      # programs.go.env only reaches the go command; other tools read $GOPATH.
      home.sessionVariables.GOPATH = goPath;

      programs.go = {
        enable = true;
        env.GOPATH = goPath;
      };
    };
  }
