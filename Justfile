set quiet

# Run "nix flake update"
update:
  nix flake update

# Build an image for a given host
build-image $host:
  nix build .#nixosConfigurations.${host}.config.system.build.diskoImagesScript
  ./result
  zstd main.raw -o main.raw.zstd --adapt

# Upload an image to Hetzner
upload-image $file:
  hcloud-upload-image upload \
    --architecture x86 \
    --compression zstd \
    --description "Image for hetzner-fi-1 (github:pinkwah/hosts)" \
    --image-path $file


# Deploy NixOS to an existing and configured host
deploy $host: (copy host)
  nixos-rebuild-ng switch --flake .#{{host}} --target-host root@{{host}} --build-host root@{{host}} --no-reexec

# Copy NixOS configuration to a host without switching to it
copy $host:
  rsync -ar --delete --chown=root:root ./ root@{{host}}:/etc/nixos/
