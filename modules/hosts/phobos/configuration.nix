{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./nextcloud.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Workaround for https://github.com/NixOS/nix/issues/8502
  services.logrotate.checkConfig = false;

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "phobos";
  networking.domain = "hosts.zohar.no";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # RosaMain
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7wrK4sA6acnwKJ9D6OUMajkvaax9+3PyWUmTxrtnHx"
  ];
  system.stateVersion = "25.11";

  users.users.nextcloud.uid = 995;
  users.groups.nextcloud.gid = 993;

  services.nginx = {
    virtualHosts = {
      "docs.zohar.no" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
          proxyWebsockets = true;
        };
      };
    };
  };

  # https://diogotc.com/blog/collabora-nextcloud-nixos/#deploy-collabora-with-nixos
  services.collabora-online = {
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

      server_name = "docs.zohar.no";
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "docs.zohar.no".email = "letsencrypt@zohar.no";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
