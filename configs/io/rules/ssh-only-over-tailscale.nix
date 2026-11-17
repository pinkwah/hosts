# Only allow SSH over tailscale so it's not possible to connect to this server
# via the public internet.
_:

{
  services = {
    openssh = {
      enable = true;

      # This service automatically opens the firewall for port 22 on all NICs.
      # We can disable it here and then trust the tailscale0 device and it'll work.
      openFirewall = false;
    };

    tailscale = {
      enable = true;
    };
  };

  networking = {
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
    };
  };
}
