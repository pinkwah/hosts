# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ lib, pkgs, ... }:
let

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANc9pIqHgW3scSpJl9P1uRJy5GR1qHMf/hWLchzv7za"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7wrK4sA6acnwKJ9D6OUMajkvaax9+3PyWUmTxrtnHx"
  ];

  serviceNames = lib.attrNames (
    lib.filterAttrs (_: value: value == "regular") (lib.readDir ./services)
  );
  services = map (name: ./services/${name}) serviceNames;

in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ]
  ++ services;

  nix = {
    settings = {
      extra-experimental-features = [
        "flakes"
        "nix-command"
      ];
      trusted-users = [
        "zohar"
        "root"
      ];
    };
  };

  # Use the GRUB 2 boot loader.
  boot = {
    loader = {
      systemd-boot.enable = false;

      grub = {
        enable = true;
        efiSupport = false;
        devices = [
          "/dev/nvme0n1"
          "/dev/nvme1n1"
        ];
        copyKernels = true;
      };
    };

    supportedFilesystems = [ "zfs" ];
    swraid.enable = true;
    kernelParams = [ "boot.shell_on_fail" ];
    zfs.forceImportRoot = false;
  };

  networking = {
    hostName = "io";
    domain = "hosts.zohar.no";
    hostId = "00000001";
    useDHCP = false;

    interfaces.enp9s0 = {
      ipv4.addresses = [
        {
          address = "65.21.239.222";
          prefixLength = 32;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a01:4f9:6a:4f12::1";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway = {
      address = "65.21.239.193";
      interface = "enp9s0";
    };

    defaultGateway6 = {
      address = "fe80::1";
      interface = "enp9s0";
    };

    nameservers = [
      # Cloudflare
      "1.1.1.1"
      "2606:4700:4700:1111"
      "2606:4700:4700:1001"

      # Google
      "8.8.8.8"
      "2001:4860:4860:8888"
      "2001:4860:4860:8844"
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  users.users = {
    root = {
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = authorizedKeys;
    };

    zohar = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = authorizedKeys;
      shell = pkgs.fish;
      extraGroups = [ "podman" ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
      };
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  programs = {
    fish.enable = true;
    git.enable = true;
  };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    borgbackup
    vim
    wget
  ];

  services = {
    borgmatic = {
      enable = true;

      configurations = {
        zfs = { };
      };

      settings = {
        repositories = [
          {
            label = "hetzner";
            path = "ssh://u503778-sub1@u503778-sub1.your-storagebox.de:23/./borg";
          }
        ];
      };
    };
  };

  system.stateVersion = "26.05";
}
