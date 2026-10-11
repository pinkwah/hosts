{ config, ... }:

let
  cfg = config.services.keycloak;
  hostname = "auth.zohar.no";
  http-port = cfg.settings.http-port;
in {
  services = {
    keycloak = {
      enable = true;

      database = {
        type = "postgresql";
        createLocally = true;
      };

      settings = {
        inherit hostname;
        http-port = 38080;
        http-enabled = true;
        proxy = "passthrough";
      };
    };

    nginx.virtualHosts."${hostname}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://localhost:${toString http-port}";
      };
    };
  };
}
