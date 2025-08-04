_: {
  config = {
    age.secrets = {
      backups-common-rclone = {
        file = ../../secrets/backups-common-rclone.age;
      };

      backups-common-env = {
        file = ../../secrets/backups-common-env.age;
      };

      backups-common-password = {
        file = ../../secrets/backups-common-password.age;
      };
    };
  };
}
