{...}: {
  home-manager = {
    users.dsully = {
      programs = {
        git = {
          userEmail = "dsully@users.noreply.github.com";
        };
      };
    };
  };
}
