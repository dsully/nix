{
  config,
  lib,
  ...
}:
with lib; {
  options.system = {
    fullName = mkOption {
      type = types.nullOr types.str;
      default = "Dan Sully";
    };

    hostName = mkOption {
      type = types.nullOr types.str;
    };

    userName = mkOption {
      type = types.nullOr types.str;
      default = "dsully";
    };
  };

  config = {
    assertions = [
      {
        assertion = config.system.fullName != null;
        message = "The option 'system.fullName' must be set to a non-null value";
      }
      {
        assertion = config.system.hostName != null;
        message = "The option 'system.hostName' must be set to a non-null value";
      }
      {
        assertion = config.system.userName != null;
        message = "The option 'system.userName' must be set to a non-null value";
      }
    ];
  };
}
