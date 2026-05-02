{
  config,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    davfs2
  ];

  sops.secrets.davfs = {
    mode = "0600";
    path = "/etc/davfs2/secrets";
  };

  services.davfs2.enable = true;

  systemd.mounts = [
    {
      description = "Hetzner Storage Box 'deimos'";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      what = "https://u503778.your-storagebox.de";
      where = "/mnt/store";
      options = "x-systemd.automount";
      type = "davfs";
    }
  ];

  systemd.automounts = [
    {
      description = "Hetzner Storage Box 'deimos' automount";
      where = "/mnt/store";
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "2m";
      };
    }
  ];
}
