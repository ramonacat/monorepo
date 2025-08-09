_: {
  config = {
    age.secrets = {
      backups-public-rclone = {
        file = ../../secrets/backups-public-rclone.age;
      };

      backups-public-env = {
        file = ../../secrets/backups-public-env.age;
      };

      backups-public-password = {
        file = ../../secrets/backups-public-password.age;
      };
    };
  };
}
