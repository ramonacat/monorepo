{pkgs}: rec {
  inherit (pkgs.nodePackages_latest) nodejs;
  php = pkgs.php84;
  phpPackages = pkgs.php84Packages;
  php-dev = php.buildEnv {
    extensions = {
      enabled,
      all,
    }:
      enabled ++ [all.xdebug];
    extraConfig = ''
      memory_limit=1G
      xdebug.mode=coverage
      zend.exception_string_param_max_len=128
    '';
  };
}
