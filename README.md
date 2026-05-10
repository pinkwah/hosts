# Pinkwah's NixOS hosts

This is my NixOS configurations for deploying 

## Phobos

This is currently my only node, which is just a cheapo Hetzner node.

It is currently hosting:
* [Nextcloud](https://sky.zohar.no)
* [OnlyOffice](https://docs.zohar.no)
* PostgreSQL

## Bootstrapping

We generate an image that we then upload to Hetzner.

First, create host SSH keys by running `just keygen`. This creates a `key/` directory containing SSH keys and the "age" key.

Place the contents of the age file into `.sops.yaml` for the correct secrets section.
