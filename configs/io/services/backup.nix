{ config, lib, ... }:
{
  services = {
    borgmatic = {
      enable = true;

      settings = {
        repositories = [
          {
            label = "hetzner";
            path = "ssh://u503778-sub1@u503778-sub1.your-storagebox.de:23/./borg";
          }
        ];

        encryption_passcommand = "cat ${lib.escapeShellArg config.sops.secrets.borgmatic-password.path}";

        ssh_command = "ssh -i ${lib.escapeShellArg config.sops.secrets.borgmatic-ed25519.path} -p 23";

        keep_monthly = 6;

        postgresql_databases = [
          {
            name = "all";
            username = "postgres";
          }
        ];

        # zfs = {
        # zfs_command = "/run/current-system/sw/bin/zfs";
        # mount_command = "/run/wrappers/bin/mount";
        # umount_command = "/run/wrappers/bin/umount";
        # };
      };
    };
  };

  sops.secrets = {
    borgmatic-ed25519 = { };
    borgmatic-password = { };
  };
}
