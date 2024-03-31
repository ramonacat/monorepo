_: {
  config = {
    age.secrets.minio-terraform-state = {
      file = ../secrets/minio-terraform-state.age;
      owner = "ramona";
    };

    age.secrets.terraform-tokens = {
      file = ../secrets/terraform-tokens.age;
      owner = "ramona";
    };
  };
}
