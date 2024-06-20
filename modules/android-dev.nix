{pkgs, ...}: {
  config = {
    home-manager.users.ramona.home.packages = with pkgs; [
      android-studio
      androidenv.androidPkgs.androidsdk
      androidenv.androidPkgs.platform-tools
    ];
  };
}
