set quiet

update:
  nix flake update

build-iso $host:
  nixos-generate --flake .#{{host}} -c ./modules/installer -f install-iso -I nixpkgs=channel:nixos-25.11

check:
  nix flake check

deploy $host: (copy host)
  nixos-rebuild-ng switch --flake .#{{host}} --target-host root@{{host}} --build-host root@{{host}} --no-reexec

copy $host:
  rsync -ar --delete --chown=root:root ./ root@{{host}}:/etc/nixos/
