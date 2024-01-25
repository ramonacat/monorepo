{ ... }: {
  config = {
    services.paperless = {
      enable = true;
      address = "0.0.0.0";
      port = 58080;
      dataDir = "/mnt/nas3/paperless/data/";
      mediaDir = "/mnt/nas3/paperless/media/";
      consumptionDir = "/mnt/nas3/data/paperless-import/";
      consumptionDirIsPublic = true;
      extraConfig = {
        PAPERLESS_OCR_LANGUAGE = "deu+eng+pol";
      };
    };
  };
}
