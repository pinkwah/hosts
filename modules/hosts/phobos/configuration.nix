{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./nextcloud.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;

    overlays = [
      # Use memos from unstable nixpkgs branch
      (final: prev: {
        inherit (import inputs.nixpkgs-unstable { inherit (prev.stdenv.hostPlatform) system; }) memos;
      })
    ];
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # RosaMain
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7wrK4sA6acnwKJ9D6OUMajkvaax9+3PyWUmTxrtnHx"
    # RosaAsus
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANc9pIqHgW3scSpJl9P1uRJy5GR1qHMf/hWLchzv7za"
  ];
  system.stateVersion = "25.11";

  users.users.nextcloud.uid = 995;
  users.groups.nextcloud.gid = 993;

  services = {
    cockpit = {
      enable = true;
      plugins = with pkgs; [
        cockpit-files
        cockpit-podman
      ];
    };

    openssh = {
      enable = true;
      openFirewall = false;
    };

    memos = {
      enable = true;
      settings = {
        MEMOS_MODE = "prod";
        MEMOS_PORT = "5230";
        MEMOS_INSTANCE_URL = "https://wah.pink/memos";
        MEMOS_DATA = config.services.memos.dataDir;
      };
    };
  };

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

      "wah.pink" = {
        forceSSL = true;
        enableACME = true;

        locations."/memos" = {
          proxyPass = "https://[::1]:${config.services.memos.settings.MEMOS_PORT}";
          proxyWebsockets = true;
        };
      };
    };

    tailscaleAuth = {
      enable = true;
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

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "docs.zohar.no".email = "letsencrypt@zohar.no";
    };
  };

  networking = {
    hostName = "phobos";
    domain = "hosts.zohar.no";

    nftables.enable = true;

    firewall = {
      allowedTCPPorts = [
        80
        443
      ];

      trustedInterfaces = [ "tailscale0" ];
    };
  };

}
