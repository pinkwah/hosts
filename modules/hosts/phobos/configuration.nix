{
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./servers/collabora.nix
    ./servers/memos.nix
    ./servers/nextcloud.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  users = {
    users = {
      root = {
        openssh.authorizedKeys.keys = [
          # RosaMain
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7wrK4sA6acnwKJ9D6OUMajkvaax9+3PyWUmTxrtnHx"
          # RosaAsus
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANc9pIqHgW3scSpJl9P1uRJy5GR1qHMf/hWLchzv7za"
        ];
      };
    };
  };

  system.stateVersion = "25.11";

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
  };

  services.nginx = {
    tailscaleAuth = {
      enable = true;
    };
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
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
