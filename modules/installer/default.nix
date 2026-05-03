{ pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "nb_NO.UTF-8/UTF-8"
  ];
  i18n.defaultLocale = "nb_NO.UTF-8";

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    rsync
    wget
    curl
    rxvt-unicode
  ];

  programs.git.enable = true;
  programs.fish.enable = true;
  programs.neovim.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      LoginGraceTime = 0;
      PermitRootLogin = "yes";
    };
  };

  system.stateVersion = "25.11";
}
