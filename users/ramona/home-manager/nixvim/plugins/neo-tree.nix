_: {
  config = {
    programs.nixvim.plugins.neo-tree = {
      enable = true;
      filesystem = {
        useLibuvFileWatcher = true;
        followCurrentFile.enabled = true;
        filteredItems.alwaysShow = [
          ".github"
          ".gitignore"
        ];
      };
    };
  };
}
