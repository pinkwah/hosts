{
  inputs,
  ...
}:

inputs.nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  system = "aarch64-linux";
  modules = [
    ./configuration.nix

    inputs.sops-nix.nixosModules.sops

    {
      sops.defaultSopsFile = ./secrets.yaml;
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    }
  ];
}
