{pkgs, ...}: {
  programs.gh = {
    enable = true;
    settings = {
      aliases = {
        # Repository
        r = "repo";
        ro = "repo view --web";
        rv = "repo view";
        rl = "repo list";
        # Issues
        il = "issue list";
        im = "issue list --assignee @me";
        bugs = "issue list --label=\"bugs\"";
        is = "issue status";
        iv = "issue view";
        ic = "issue create";
        ie = "issue edit";
        # Pull Request
        prs = "search prs --author @me --state open";
        wip = "search prs --review-requested=@me --state=open";
        co = "pr checkout";
        ps = "pr status";
        pv = "pr view --web";
        # Gist
        gl = "gist list";
        gv = "gist view";
        gc = "gist create";
        ge = "gist edit";
      };
      editor = "${pkgs.lib.getExe pkgs.neovim}";
      git_protocol = "ssh";
      pager = "${pkgs.lib.getExe pkgs.delta}";
      prompt = "enabled";
    };
    extensions = with pkgs; [
      gh-dash
      gh-poi
    ];
  };
}
