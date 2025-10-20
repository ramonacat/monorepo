_: {
  config = {
    programs.nixvim.plugins.neo-tree = {
      enable = true;
      settings.filesystem = {
        use_libuv_file_watcher = true;
        follow_current_file.enabled = true;
        filtered_items.always_show = [
          ".github"
          ".gitignore"
        ];
      };
    };
  };
}
