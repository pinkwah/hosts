{
  config,
  pkgs,
  ...
}:

let

  uid = 995;
  gid = 993;

in

{
  environment.systemPackages = with pkgs; [
    davfs2
  ];

  security.acme.certs."sky.zohar.no".email = "letsencrypt@zohar.no";

  sops.secrets = {
    nextcloud = {
      mode = "0600";
      path = "/etc/nextcloud-admin-pass";
    };

    davfs = {
      mode = "0600";
      path = "/etc/davfs2/secrets";
    };
  };

  services = {
    davfs2.enable = true;

    nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;
      hostName = "sky.zohar.no";
      https = true;
      database.createLocally = true;

      # appstoreEnable = false;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit
          calendar
          contacts
          deck
          notes
          richdocuments
          tasks
          ;
      };
      extraAppsEnable = true;

      config = {
        dbtype = "pgsql";
        adminuser = "admin";
        adminpassFile = "/etc/nextcloud-admin-pass";
      };
    };

    nginx.virtualHosts."sky.zohar.no" = {
      forceSSL = true;
      enableACME = true;
    };
  };

  fileSystems."${config.services.nextcloud.home}/data" = {
    device = "https://u503778.your-storagebox.de";
    fsType = "davfs";
    options = [
      "uid=${toString uid}"
      "gid=${toString gid}"
      "rw"
      "x-systemd.automount"
    ];
  };

  # Use a specific uid/gid for the nextcloud user due to legacy
  users = {
    users.nextcloud.uid = uid;
    groups.nextcloud.gid = gid;
  };
}
