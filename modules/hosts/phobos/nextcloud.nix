{
  config,
  pkgs,
  ...
}:
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

  services.davfs2.enable = true;

  services.nextcloud = {
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
        mail
        notes
        onlyoffice
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

  services.nginx.virtualHosts."sky.zohar.no" = {
    forceSSL = true;
    enableACME = true;
  };

  systemd.mounts = [
    {
      description = "Hetzner Storage Box 'deimos'";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      what = "https://u503778.your-storagebox.de";
      where = "${config.services.nextcloud.home}/data";
      options = "x-systemd.automount,uid=995,gid=993,file_mode=0660,dir_mode=0770";
      type = "davfs";
    }
  ];

  systemd.automounts = [
    {
      description = "Hetzner Storage Box 'deimos' automount";
      where = "${config.services.nextcloud.home}/data";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "2m";
      };
    }
  ];
}
