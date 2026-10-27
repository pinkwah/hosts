{ config, ... }:

{
  # https://diogotc.com/blog/collabora-nextcloud-nixos/#deploy-collabora-with-nixos
  services = {
    collabora-online = {
      enable = true;
      settings = {
        ssl = {
          enable = false;
          termination = true;
        };

        net = {
          listen = "loopback";
          post_allow.host = [ "::1" ];
        };

        storage.wopi = {
          "@allow" = true;
          host = [ "sky.zohar.no" ];
        };

        server_name = "docs.zohar.no";
      };
    };

    nginx.virtualHosts."docs.zohar.no" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
        proxyWebsockets = true;
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "docs.zohar.no".email = "letsencrypt@zohar.no";
    };
  };
}
