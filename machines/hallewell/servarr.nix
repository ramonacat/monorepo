{
  config,
  pkgs,
  ...
}: {
  config = let
    flaresolver-port = 8191;
  in {
    age.secrets = {
      radarr-api-key = {
        inherit (config.services.recyclarr) group;

        file = ../../secrets/radarr-api-key.age;
        mode = "440";
      };
      sonarr-api-key = {
        inherit (config.services.recyclarr) group;

        file = ../../secrets/sonarr-api-key.age;
        mode = "440";
      };
    };
    services = {
      radarr = {
        enable = true;
        user = "nas";
      };
      sonarr = {
        enable = true;
        user = "nas";

        settings = {
          server.port = 8990;
        };
      };
      lidarr = {
        enable = true;
        user = "nas";

        settings = {
          server.port = 8991;
        };
      };
      prowlarr = {
        enable = true;
      };
      recyclarr = {
        enable = true;
        configuration = {
          radarr = {
            radarr-main = {
              api_key = {_secret = config.age.secrets.radarr-api-key.path;};
              base_url = "http://localhost:${toString config.services.radarr.settings.server.port}";

              include = [
                {template = "radarr-quality-definition-movie";}
                {template = "radarr-quality-profile-remux-web-2160p";}
              ];

              delete_old_custom_formats = true;
              replace_existing_custom_formats = true;
              custom_formats = [
                {
                  trash_ids = [
                    "b337d6812e06c200ec9a2d3cfa9d20a7" # DV-Boost
                    "caa37d0df9c348912df1fb1d88f9273a" # HDR10Plus Boost

                    # this is based on: https://github.com/recyclarr/config-templates/blob/dd49e8697c8bed32f7d1f4bcf1f12b8ccbedd776/radarr/includes/custom-formats/radarr-custom-formats-remux-web-2160p.yml
                    # the difference is that assign_scores_to in our config sets it for two formats
                    # Unified HDR
                    "493b6d1dbec3c3364c59d7607f7e3405" # HDR

                    # HQ Release Groups
                    "3a3ff47579026e76d6504ebea39390de" # Remux Tier 01
                    "9f98181fe5a3fbeb0cc29340da2a468a" # Remux Tier 02
                    "8baaf0b3142bf4d94c42a724f034e27a" # Remux Tier 03
                    "c20f169ef63c5f40c2def54abaf4438e" # WEB Tier 01
                    "403816d65392c79236dcb6dd591aeda4" # WEB Tier 02
                    "af94e0fe497124d1f9ce732069ec8c3b" # WEB Tier 03

                    # Misc
                    "e7718d7a3ce595f289bfee26adc178f5" # Repack/Proper
                    "ae43b294509409a6a13919dedd4764c4" # Repack2
                    "5caaaa1c08c1742aa4342d8c4cc463f2" # Repack3

                    # Unwanted
                    "ed38b889b31be83fda192888e2286d83" # BR-DISK
                    "e6886871085226c3da1830830146846c" # Generated Dynamic HDR
                    "90a6f9a284dff5103f6346090e6280c8" # LQ
                    "e204b80c87be9497a8a6eaff48f72905" # LQ (Release Title)
                    "dc98083864ea246d05a42df0d05f81cc" # x265 (HD)
                    "b8cd450cbfa689c0259a01d9e29ba3d6" # 3D
                    "bfd8eb01832d646a0a89c4deb46f8564" # Upscaled
                    "0a3f082873eb454bde444150b70253cc" # Extras
                    "712d74cd88bceb883ee32f773656b1f5" # Sing-Along Versions
                    "cae4ca30163749b891686f95532519bd" # AV1
                    "ae9b7c9ebde1f3bd336a8cbd1ec4c5e5" # No-RlsGroup

                    # Movie Versions
                    "570bc9ebecd92723d2d21500f4be314c" # Remaster
                    "eca37840c13c6ef2dd0262b141a5482f" # 4K Remaster
                    "e0c07d59beb37348e975a930d5e50319" # Criterion Collection
                    "9d27d9d2181838f76dee150882bdc58c" # Masters of Cinema
                    "db9b4c4b53d312a3ca5f1378f6440fc9" # Vinegar Syndrome
                    "957d0f44b592285f26449575e8b1167e" # Special Edition
                    "eecf3a857724171f968a66cb5719e152" # IMAX
                    "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                    "957d0f44b592285f26449575e8b1167e" # Special Edition

                    # Streaming Services
                    "cc5e51a9e85a6296ceefe097a77f12f4" # BCORE
                    "16622a6911d1ab5d5b8b713d5b0036d4" # CRiT
                    "2a6039655313bf5dab1e43523b62c374" # MA

                    # Streaming Services
                    "b3b3a6ac74ecbd56bcdbefa4799fb9df" # AMZN
                    "40e9380490e748672c2522eaaeb692f7" # ATVP
                    "84272245b2988854bfb76a16e60baea5" # DSNP
                    "509e5f41146e278f9eab1ddaceb34515" # HBO
                    "5763d1b0ce84aff3b21038eea8e9b8ad" # HMAX
                    "526d445d4c16214309f0fd2b3be18a89" # Hulu
                    "e0ec9672be6cac914ffad34a6b077209" # iT
                    "6a061313d22e51e0f25b7cd4dc065233" # MAX
                    "170b1d363bd8516fbf3a3eb05d4faff6" # NF
                    "c9fd353f8f5f1baf56dc601c4cb29920" # PCOK
                    "e36a0ba1bc902b26ee40818a1d59b8bd" # PMTP
                    "c2863d2a50c9acad1fb50e53ece60817" # STAN

                    # Audio Formats
                    "496f355514737f7d83bf7aa4d24f8169" # TrueHD ATMOS
                    "2f22d89048b01681dde8afe203bf2e95" # DTS X
                    "417804f7f2c4308c1f4c5d380d4c4475" # ATMOS (undefined)
                    "1af239278386be2919e1bcee0bde047e" # DDPlus ATMOS
                    "3cafb66171b47f226146a0770576870f" # TrueHD
                    "dcf3ec6938fa32445f590a4da84256cd" # DTS-HD MA
                    "a570d4a0e56a2874b64e5bfa55202a1b" # FLAC
                    "e7c2fcae07cbada050a0af3357491d7b" # PCM
                    "8e109e50e0a0b83a5098b056e13bf6db" # DTS-HD HRA
                    "185f1dd7264c4562b9022d963ac37424" # DDPlus
                    "f9f847ac70a0af62ea4a08280b859636" # DTS-ES
                    "1c1a4c5e823891c75bc50380a6866f73" # DTS
                    "240770601cc226190c367ef59aba7463" # AAC
                    "c2998bd0d90ed5621d8df281e839436e" # DD
                    "6ba9033150e7896bdc9ec4b44f2b230f" # MP3
                    "a061e2e700f81932daf888599f8a8273" # Opus
                  ];
                  assign_scores_to = [
                    {name = "Remux + WEB 2160p";}
                    {name = "Remux + WEB 2160p (PL)";}
                    {name = "Remux + WEB 2160p (IT)";}
                  ];
                }
              ];
              quality_profiles = let
                quality-profile-common = {
                  reset_unmatched_scores = {enabled = true;};
                  upgrade = {
                    allowed = true;
                    until_quality = "Remux-2160p";
                    until_score = "100000";
                  };
                  qualities = [
                    {name = "Remux-2160p";}
                    {name = "Bluray-2160p";}
                    {
                      name = "WEB 2160p";
                      qualities = ["WEBDL-2160p" "WEBRip-2160p"];
                    }
                    {name = "HDTV-2160p";}
                    {name = "Remux-1080p";}
                    {name = "Bluray-1080p";}
                    {
                      name = "WEB 1080p";
                      qualities = ["WEBDL-1080p" "WEBRip-1080p"];
                    }
                    {name = "HDTV-1080p";}
                    {name = "Bluray-720p";}
                    {
                      name = "WEB 720p";
                      qualities = ["WEBDL-720p" "WEBRip-720p"];
                    }
                    {name = "HDTV-720p";}
                    {name = "Bluray-576p";}
                    {name = "Bluray-480p";}
                    {
                      name = "WEB 480p";
                      qualities = ["WEBDL-480p" "WEBRip-480p"];
                    }
                    {name = "SDTV";}
                  ];
                };
              in [
                (quality-profile-common
                  // {
                    name = "Remux + WEB 2160p";
                  })
                (quality-profile-common
                  // {
                    # This is the same as above but with PL as the language (languages have to be set in the UI).
                    name = "Remux + WEB 2160p (PL)";
                  })
                (quality-profile-common
                  // {
                    # This is the same as above but with IT as the language (languages have to be set in the UI).
                    name = "Remux + WEB 2160p (IT)";
                  })
              ];
            };
          };
          sonarr = {
            sonarr-main = {
              api_key = {_secret = config.age.secrets.sonarr-api-key.path;};
              base_url = "http://localhost:${toString config.services.sonarr.settings.server.port}";

              include = [
                {template = "sonarr-quality-definition-series";}
              ];

              delete_old_custom_formats = true;
              replace_existing_custom_formats = true;

              custom_formats = [
                {
                  "trash_ids" = [
                    "7c3a61a9c6cb04f52f1544be6d44a026" # DV Boost
                    "0c4b99df9206d2cfac3c05ab897dd62a" # HDR10+ Boost
                    "9965a052eb87b0d10313b1cea89eb451" # Remux Tier 01
                    "8a1d0c3d7497e741736761a1da866a2e" # Remux Tier 02
                    "e6886871085226c3da1830830146846c" # Generated Dynamic HDR

                    # this is degermanised version of https://github.com/recyclarr/config-templates/blob/dd49e8697c8bed32f7d1f4bcf1f12b8ccbedd776/sonarr/includes/custom-formats/sonarr-v4-custom-formats-uhd-remux-web-german.yml
                    # Unified HDR
                    "505d871304820ba7106b693be6fe4a9e" # HDR

                    # HQ Source Groups
                    "e6258996055b9fbab7e9cb2f75819294" # WEB Tier 01
                    "58790d4e2fdcd9733aa7ae68ba2bb503" # WEB Tier 02
                    "d84935abd3f8556dcd51d4f27e22d0a6" # WEB Tier 03
                    "d0c516558625b04b363fa6c5c2c7cfd4" # WEB Scene

                    # Misc
                    "ec8fa7296b64e8cd390a1600981f3923" # Repack/Proper
                    "eb3d5cc0a2be0db205fb823640db6a3c" # Repack2
                    "44e7c4de10ae50265753082e5dc76047" # Repack3

                    # Resolution
                    "c99279ee27a154c2f20d1d505cc99e25" # 720p
                    "290078c8b266272a5cc8e251b5e2eb0b" # 1080p
                    "1bef6c151fa35093015b0bfef18279e5" # 2160p

                    # Unwanted
                    "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
                    "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
                    "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
                    "47435ece6b99a0b477caf360e79ba0bb" # x265 (HD)
                    "23297a736ca77c0fc8e70f8edd7ee56c" # Upscaled
                    "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
                    "15a05bc7c1a36e2b57fd628f8977e2fc" # AV1
                    "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup

                    # Streaming Services
                    "d660701077794679fd59e8bdf4ce3a29" # AMZN
                    "f67c9ca88f463a48346062e8ad07713f" # ATVP
                    "77a7b25585c18af08f60b1547bb9b4fb" # CC
                    "36b72f59f4ea20aad9316f475f2d9fbb" # DCU
                    "dc5f2bb0e0262155b5fedd0f6c5d2b55" # DSCP
                    "89358767a60cc28783cdc3d0be9388a4" # DSNP
                    "7a235133c87f7da4c8cccceca7e3c7a6" # HBO
                    "a880d6abc21e7c16884f3ae393f84179" # HMAX
                    "f6cce30f1733d5c8194222a7507909bb" # Hulu
                    "0ac24a2a68a9700bcb7eeca8e5cd644c" # iT
                    "81d1fbf600e2540cee87f3a23f9d3c1c" # MAX
                    "d34870697c9db575f17700212167be23" # NF
                    "1656adc6d7bb2c8cca6acfb6592db421" # PCOK
                    "c67a75ae4a1715f2bb4d492755ba4195" # PMTP
                    "ae58039e1319178e6be73caab5c42166" # SHO
                    "1efe8da11bfd74fbbcd4d8117ddb9213" # STAN
                    "9623c5c9cac8e939c1b9aedd32f640bf" # SYFY

                    # Audio Formats
                    "0d7824bb924701997f874e7ff7d4844a" # TrueHD ATMOS
                    "9d00418ba386a083fbf4d58235fc37ef" # DTS X
                    "b6fbafa7942952a13e17e2b1152b539a" # ATMOS (undefined)
                    "4232a509ce60c4e208d13825b7c06264" # DDPlus ATMOS
                    "1808e4b9cee74e064dfae3f1db99dbfe" # TrueHD
                    "c429417a57ea8c41d57e6990a8b0033f" # DTS-HD MA
                    "851bd64e04c9374c51102be3dd9ae4cc" # FLAC
                    "30f70576671ca933adbdcfc736a69718" # PCM
                    "cfa5fbd8f02a86fc55d8d223d06a5e1f" # DTS-HD HRA
                    "63487786a8b01b7f20dd2bc90dd4a477" # DDPlus
                    "c1a25cd67b5d2e08287c957b1eb903ec" # DTS-ES
                    "5964f2a8b3be407d083498e4459d05d0" # DTS
                    "a50b8a0c62274a7c38b09a9619ba9d86" # AAC
                    "dbe00161b08a25ac6154c55f95e6318d" # DD
                    "3e8b714263b26f486972ee1e0fe7606c" # MP3
                    "28f6ef16d61e2d1adfce3156ed8257e3" # Opus
                  ];
                  assign_scores_to = [
                    {name = "Remux + WEB 2160p";}
                    {name = "Remux + WEB 2160p (PL)";}
                    {name = "Remux + WEB 2160p (IT)";}
                  ];
                }
              ];
              quality_profiles = let
                quality-profile-common = {
                  upgrade = {
                    allowed = true;
                    until_quality = "Bluray-2160p Remux";
                    until_score = "100000";
                  };
                  qualities = [
                    {name = "Bluray-2160p Remux";}
                    {name = "Bluray-2160p";}
                    {
                      name = "WEB 2160p";
                      qualities = ["WEBDL-2160p" "WEBRip-2160p"];
                    }
                    {name = "HDTV-2160p";}
                    {name = "Bluray-1080p Remux";}
                    {name = "Bluray-1080p";}
                    {
                      name = "WEB 1080p";
                      qualities = ["WEBDL-1080p" "WEBRip-1080p"];
                    }
                    {name = "HDTV-1080p";}
                    {name = "Bluray-720p";}
                    {
                      name = "WEB 720p";
                      qualities = ["WEBDL-720p" "WEBRip-720p"];
                    }
                    {name = "HDTV-720p";}
                    {name = "Bluray-576p";}
                    {name = "Bluray-480p";}
                    {
                      name = "WEB 480p";
                      qualities = ["WEBDL-480p" "WEBRip-480p"];
                    }
                    {name = "SDTV";}
                    {name = "DVD";}
                  ];
                };
              in [
                (quality-profile-common
                  // {
                    name = "Remux + WEB 2160p";
                  })
                (quality-profile-common
                  // {
                    name = "Remux + WEB 2160p (PL)";
                  })
                (quality-profile-common
                  // {
                    name = "Remux + WEB 2160p (IT)";
                  })
              ];
            };
          };
        };
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
      config.services.radarr.settings.server.port
      config.services.sonarr.settings.server.port
      config.services.lidarr.settings.server.port
      config.services.prowlarr.settings.server.port
      flaresolver-port
    ];

    virtualisation.oci-containers.containers.flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = ["0.0.0.0:${builtins.toString flaresolver-port}:${builtins.toString flaresolver-port}"];
      environment = {
        LOG_LEVEL = "debug";
      };
      extraOptions = ["--network=host"];
    };

    services.restic.backups.servarr = import ../../libs/nix/mk-restic-config.nix {inherit config pkgs;} {
      timerConfig = {
        OnCalendar = "*-*-* 00/1:00:00";
        RandomizedDelaySec = "30m";
      };
      paths = [
        config.services.sonarr.dataDir
        config.services.radarr.dataDir
        config.services.lidarr.dataDir
        # this path seems to be hardcoded in the service definition
        "/var/lib/prowlarr"
      ];
    };
  };
}
