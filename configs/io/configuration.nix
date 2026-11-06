# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, ... }:
let

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANc9pIqHgW3scSpJl9P1uRJy5GR1qHMf/hWLchzv7za"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7wrK4sA6acnwKJ9D6OUMajkvaax9+3PyWUmTxrtnHx"
  ];

in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

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

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     tree
  #   ];
  # };

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

  system = {
    autoUpgrade = {
      enable = true;
      flake = "/root/nixos-config";
      flags = [
        "--print-build-logs"
        "--commit-lock-file"
      ];
      dates = "02:00";
      randomizedDelaySec = "45min";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?

}
