{
  description = "Configurations for my hosts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    deploy-rs.url = "github:serokell/deploy-rs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      deploy-rs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        ...
      }:
      {
        systems = [ "x86_64-linux" ];
        imports = [ ];

        perSystem =
          { pkgs, ... }:
          {
            packages = {
              inherit (pkgs) deploy-rs;
            };

            formatter = pkgs.nixfmt-tree;
          };

        flake = {
          nixosConfigurations = {
            hetzner-fi-1 = import ./modules/hosts/hetzner-fi-1 { inherit self inputs; };
          };

          deploy.nodes.hetzner-fi-1 = {
            hostname = "hetzner-fi-1.hosts.zohar.no";
            profiles.system = {
              sshUser = "root";
              user = "root";
              path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.hetzner-fi-1;
            };
          };

          # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
        };
      }
    );
}
