{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  # fileSystems."/boot/efi" = {
  #   device = "/dev/disk/by-uuid/7AE2-203E";
  #   fsType = "vfat";
  # };
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "xen_blkfront"
  ];
  boot.initrd.kernelModules = [ "nvme" ];
  # fileSystems."/" = {
  # device = "/dev/sda1";
  # fsType = "ext4";
  # };

}
