{
  inputs,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  # system = "aarch64-linux";
  system = "x86_64-linux";
  modules = [
    ./configuration.nix
    ./disko.nix

    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops

    {
      sops.defaultSopsFile = ./secrets.yaml;
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    }
  ];
}
