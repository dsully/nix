{
  mkUserModule,
  lib,
  pkgs,
  ...
}: let
  reaEnv = {
    GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
    JAVA_HOME = toString pkgs.jdk25;
    REA_KUNA_COMMAND = lib.getExe pkgs.kuna;
  };
in
  mkUserModule {
    name = "rea";
    default = false;

    home = {
      home = {
        packages = with pkgs; [
          ghidra
          kuna
          rea
        ];

        sessionVariables = reaEnv;
      };

      programs = {
        ai.skills = {
          local.manual = ["kuna-decompiler"];
          rea = {
            path = "${pkgs.rea}/lib/node_modules/rea-agents/skills";
            all = true;
            manual = true;
          };
        };

        mcp.servers.rea = {
          command = lib.getExe pkgs.rea;
          args = ["mcp"];
          enabled = false;
          env = reaEnv;
        };
      };
    };
  }
