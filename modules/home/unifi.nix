{
  ai,
  config,
  ...
}: {
  fishSecrets.UNIFI_API_KEY = "op://Services/UniFi API/credential";

  programs = {
    mcp.servers.unifi = ai.muxWrap {
      command = "${config.home.homeDirectory}/.local/bin/unifi-mcp-server";
      env = {
        UNIFI_API_TYPE = "local";
        UNIFI_DEFAULT_SITE = "default";
        UNIFI_LOCAL_HOST = "10.0.0.1";
        UNIFI_LOCAL_VERIFY_SSL = "false";
        UNIFI_SITE_MANAGER_ENABLED = "true";
      };
      enabled = false;
      stateless = true;
    };

    uv.tool.packages = ["unifi-mcp-server"];
  };
}
