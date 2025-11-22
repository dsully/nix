{pkgs, ...}: let
  yamlFormat = pkgs.formats.yaml {};
in {
  home.file.".turbocommit.yaml".source = yamlFormat.generate "turbocommit.yaml" {
    api_endpoint = "https://api.openai.com/v1/chat/completions";
    api_key_env_var = "OPENAI_API_KEY";
    disable_auto_update_check = true;
    model = "gpt-5.1-codex-mini";
    reasoning_effort = "low";
    verbosity = "medium";
  };
}
