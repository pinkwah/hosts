set quiet

# Run "nix flake update"
update:
  nix flake update

# Build an image for a given host
build-image $host:
  nix build .#nixosConfigurations.${host}.config.system.build.diskoImagesScript
  ./result \
    --post-format-files $PWD/key/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key \
    --post-format-files $PWD/key/ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key.pub \
    --post-format-files $PWD/key/ssh_host_ecdsa_key /etc/ssh/ssh_host_ecdsa_key \
    --post-format-files $PWD/key/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub \
    --post-format-files $PWD/key/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key \
    --post-format-files $PWD/key/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key.pub

  zstd -f main.raw -o main.raw.zstd --adapt

# Upload an image to Hetzner
upload-image $file:
  hcloud-upload-image upload \
    --architecture x86 \
    --compression zstd \
    --description "Image for hetzner-fi-1 (github:pinkwah/hosts)" \
    --image-path $file

# Generate a SSH key with age pub key
keygen:
  rm -r key/
  mkdir key/
  ssh-keygen -t rsa -b 4096 -P "" -f key/ssh_host_rsa_key >/dev/null
  ssh-keygen -t ed25519 -P "" -f key/ssh_host_ed25519_key >/dev/null
  ssh-keygen -t ecdsa -P "" -f key/ssh_host_ecdsa_key >/dev/null
 
  ssh-to-age -i key/ssh_host_ed25519_key.pub -o key/age
  echo "age: $(cat key/age)"
  echo
  echo "Add this to the correct place in .sops.yaml and run:"
  echo
  echo -e "\tsops updatekeys modules/hosts/[HOST]/secrets.yaml"
  echo

# Deploy NixOS to an existing and configured host
deploy $host: (copy host)
  nixos-rebuild-ng switch --flake .#{{host}} --target-host root@{{host}} --build-host root@{{host}} --no-reexec

# Copy NixOS configuration to a host without switching to it
copy $host:
  rsync -ar --exclude .git --filter ':- .gitignore' --delete --chown=root:root ./ root@{{host}}:/etc/nixos/
