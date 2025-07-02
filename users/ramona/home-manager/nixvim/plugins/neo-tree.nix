_: {
  config = {
    programs.nixvim.plugins.neo-tree = {
      enable = true;
      filesystem.followCurrentFile.enabled = true;
      filesystem.filteredItems.alwaysShow = [
        ".github"
        ".gitignore"
      ];
    };
  };
}
