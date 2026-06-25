{
  launchd.agents.pbcopy = {
    enable = true;
    config = {
      Label = "localhost.pbcopy";
      ProgramArguments = ["/usr/bin/pbcopy"];

      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };

      ProcessType = "Background";

      Sockets = {
        Listener = {
          SockNodeName = "127.0.0.1";
          SockServiceName = "2224";
        };
      };

      inetdCompatibility.Wait = false;
    };
  };

  launchd.agents.pbpaste = {
    enable = true;
    config = {
      Label = "localhost.pbpaste";
      ProgramArguments = ["/usr/bin/pbpaste"];

      KeepAlive = {
        Crashed = true;
        SuccessfulExit = false;
      };

      ProcessType = "Background";

      Sockets = {
        Listener = {
          SockNodeName = "127.0.0.1";
          SockServiceName = "2225";
        };
      };

      inetdCompatibility.Wait = false;
    };
  };
}
