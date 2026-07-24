{
  description = "Configurations for my hosts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hcloud-upload-image = {
      url = "github:apricote/hcloud-upload-image";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        ...
      }:
      {
        systems = [ "x86_64-linux" ];
        imports = [ inputs.treefmt-nix.flakeModule ];

        perSystem =
          { pkgs, system, ... }:
          {
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                just
                nh
                nixos-rebuild-ng
                nixos-generators
                hcloud
                ssh-to-age
                zstd

                inputs.hcloud-upload-image.packages.${system}.default
                inputs.deploy-rs.packages.${system}.default
              ];

              shellHook = ''
                just --list
              '';
            };

            treefmt = {
              projectRootFile = "flake.nix";
              programs.nixfmt.enable = true;
              programs.nixfmt.package = pkgs.nixfmt-rfc-style;
              programs.deadnix.enable = true;
              programs.shellcheck.enable = true;
            };
          };

        flake = {
          nixosConfigurations = {
            phobos = import ./modules/hosts/phobos { inherit self inputs; };
          };

          deploy.nodes.phobos = {
            hostname = "phobos.hosts.zohar.no";
            profiles.system = {
              sshUser = "root";
              user = "root";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.phobos;
            };
          };

          checks = builtins.mapAttrs (
            _system: deployLib: deployLib.deployChecks self.deploy
          ) inputs.deploy-rs.lib;
        };
      }
    );
}
