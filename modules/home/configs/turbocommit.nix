{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};
in {
  home.file.".turbocommit.yaml".source = yamlFormat.generate "turbocommit.yaml" {
    api_endpoint = "https://api.openai.com/v1/chat/completions";
    api_key_env_var = "OPENAI_API_KEY";
    default_number_of_choices = 3;
    disable_auto_update_check = true;
    jj_rewrite_default = false;
    model = "gpt-5.1";
    reasoning_effort = "low";
    system_msg = builtins.readFile ./turbocommit-system-msg.txt;
    verbosity = "medium";
  };
}
