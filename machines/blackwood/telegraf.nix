_: {
  config = {
    services.telegraf.extraConfig.inputs.file = {
      files = ["/var/www/ramona.fun/builds/*-closure"];
      data_format = "value";
      data_type = "string";
      name_override = "latest_closure";
      file_tag = "filename";
    };
  };
}
