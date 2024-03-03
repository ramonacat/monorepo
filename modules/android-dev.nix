{ pkgs, ... }: {
  config = {
    home-manager.users.ramona.home.packages = with pkgs; [
      android-studio
      androidenv.androidPkgs_9_0.androidsdk
      androidenv.androidPkgs_9_0.platform-tools
    ];
  };
}
