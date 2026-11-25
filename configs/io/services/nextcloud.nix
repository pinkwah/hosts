{
  config,
  pkgs,
  utils,
  ...
}:

let

  package = pkgs.nextcloud33;
  cfg = config.services.nextcloud;
  dataDir = "${cfg.home}/data";
  mountUnit = "${utils.escapeSystemdPath dataDir}.mount";

in
{
  services = {
    collabora-online = {
      enable = true;

      settings = {
        ssl = {
          enable = false;
          termination = true;
        };

        net = {
          listen = "loopback";
          post_allow.host = [ "::1" ];
        };

        storage.wopi = {
          "@allow" = true;
          host = [ "sky.zohar.no" ];
        };

        server_name = "collabora.zohar.no";
      };
    };

    nextcloud = {
      inherit package;
      enable = true;
      hostName = "sky.zohar.no";
      https = true;
      database.createLocally = true;

      extraApps = with package.packages.apps; {
        inherit
          calendar
          contacts
          deck
          notes
          richdocuments
          tasks
          user_oidc
          ;
      };
      extraAppsEnable = true;

      config = {
        dbtype = "pgsql";
        adminuser = null;
      };
    };

    nginx.virtualHosts = {
      "collabora.zohar.no" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
          proxyWebsockets = true;
        };
      };

      "sky.zohar.no" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };

  fileSystems.${dataDir} = {
    device = "//u503778-sub2.your-storagebox.de/u503778-sub2";
    fsType = "cifs";
    options = [
      "credentials=${config.sops.secrets.nextcloud-cifs-credentials.path}"
      "uid=nextcloud"
      "gid=nextcloud"
      "forceuid"
      "forcegid"
      "file_mode=0660"
      "dir_mode=0770"
      "vers=3.0"
      "iocharset=utf8"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "nofail"
      "cache=loose"
    ];
  };

  systemd.services.phpfpm-nextcloud = {
    after = [ mountUnit ];
    requires = [ mountUnit ];
  };

  sops.secrets.nextcloud-cifs-credentials = { };
}
