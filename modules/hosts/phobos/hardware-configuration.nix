{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "xen_blkfront"
    ];
    initrd.kernelModules = [ "nvme" ];
  };

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  services.resolved = {
    enable = true;
    dnssec = "true";
    domains = [ "~." ];
    dnsovertls = "true";
    fallbackDns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
