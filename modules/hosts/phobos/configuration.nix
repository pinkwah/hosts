{ ... }:
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEqB5AFV0r7CwEzotYX//8i3c82ZmsEhHYmqJzMkNyP"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1VTP5jOToZpXT93IZuyYSMbgJLlXjSTmQaVYQOWA+yrGhby71JFl9i0HgjAnNos3gGxfneGx9/meuWKi40SJFDHnZczjjEK+IK4f6RBiwevUHIKje0+VW5RdYqaj0gFhBzap22zSOG8cj6ApkeQUIAUNBL5l4gPzPHqdtpdtm+kxV3076zu48iCDbviE4M2hLS86korrKp/H//MBv6FXaiVVm9pAw1SqIvyBxFLhs4rkf1trr4MhY7ZhmLwHxKfIVQG0HdAGxUD30mE0J60lh1ImjSF9yohXZUENr1EPNn0+rvvUbMl2TISUEyQsOqhsVXj1AOs9g9XIPx8q9TyG84zQ5RleJtYr1f3oq25W8gusr9bcuvSXX9/W9aCL5oHs3taLxINMtnjBjYnStVBdocBHOzvkxbLAE8qDQ9ovEOIyHGyv4Z5Mhd/ujMIW69nnUAHXgB0JniRHoqhe+wqTd3aFxXge0/awh15gu/TmR5vaqNtoQhQMYguGPqVtU5wdh9B63lPZKt1u8l75YcvWWjlGntoP2HZEMQKoyye+9Nveu+cJn/yxAf8pee7/yDkQuW2GeG5A8IfocyJ4D5zvSZlD0Q5SuAun4ScrobD+kB9DoG6U4wCDLg+JrMF7drpZ0ECOxo+GpYXDIzy4L7TUzN3V4JuWoJril6O5qieAtmw=="
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKgvpruMT2XlimOkm4V3moITnRhl/ROoTxDDfg+c6jOz"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK7wrK4sA6acnwKJ9D6OUMajkvaax9+3PyWUmTxrtnHx"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1sg+zkbKEshlHhC5s5t+atpTqjVziHF1PR+CIfqBKF"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmHBpvxnCT9fPTnIOrBirS4nuBeScq/kZmgFKVlS1Da"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwWahurpb1qAjHAqeni5pPGs2CXvp9/k3o22P/S9HGK"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPICNGdw13XGxUXcFQ7CaNZ49Qp7gOO1PMYEACpm30jQ"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINgB3oLKTpx8IysrUgjgpnyq7rsTEDXNcZuKXBULXNW9"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANc9pIqHgW3scSpJl9P1uRJy5GR1qHMf/hWLchzv7za"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGH+b6rzUwWqbm1UWYc4KfnZXhzMlAPG9wszJxvRlHFJ"
  ];
  system.stateVersion = "23.11";

  sops.secrets.onlyoffice-security-nonce-file = {
    mode = "0600";
    path = "/etc/onlyoffice-security-nonce-file";
    owner = "nginx";
  };

  users.users.nextcloud.uid = 995;
  users.groups.nextcloud.gid = 993;

  services.nginx = {
    virtualHosts = {
      "docs.zohar.no" = {
        forceSSL = true;
        enableACME = true;
      };
    };
  };

  services.onlyoffice = {
    enable = true;
    hostname = "docs.zohar.no";
    securityNonceFile = "/etc/onlyoffice-security-nonce-file";
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
