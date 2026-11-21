{ config, ... }:

let

  domain = "io.hosts.zohar.no";
  subpath = "/grafana";
  http_addr = "127.0.0.1";
  http_port = 8100;

in
{
  services = {
    loki = {
      enable = true;

      configuration = {
        auth_enabled = false;

        server = {
          http_listen_port = 3100;
        };

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore = {
              store = "inmemory";
            };
          };
          replication_factor = 1;
          path_prefix = "/tmp/loki";
        };

        schema_config = {
          configs = [
            {
              from = "2020-05-15";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          filesystem = {
            directory = "/tmp/loki/chunks";
          };
        };
      };
    };

    grafana = {
      enable = true;

      settings = {
        database = {
          type = "postgres";
          host = "/run/postgresql";
          user = "grafana";
        };

        security = {
          secret_key = "SW2YcwTIb9zpOOhoPsMm";
        };

        server = {
          inherit http_addr http_port domain;
          enforce_domain = true;
          enable_gzip = true;
          root_url = "https://${domain}${subpath}";
          serve_from_sub_path = true;
        };
      };
    };

    nginx.virtualHosts.${domain} = {
      addSSL = true;
      enableACME = true;
      locations."${subpath}/" = {
        proxyPass = "http://${http_addr}:${toString http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };

    postgresql = {
      enable = true;

      ensureDatabases = [ "grafana" ];
      ensureUsers = [
        {
          name = "grafana";
          ensureDBOwnership = true;
        }
      ];
    };
  };

  sops.secrets.grafana-env-file = {
    restartUnits = [ "grafana.service" ];
  };

  systemd.services.grafana = {
    environment = {
      GF_AUTH_GENERIC_OAUTH_ENABLED = "true";
      GF_AUTH_GENERIC_OAUTH_NAME = "authentik";
      GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "IuwIngVU9WTu8aMURLplrD2ji3ReBjUIrrAbXPaJ";
      GF_AUTH_GENERIC_OAUTH_SCOPES = "openid profile email entitlements";
      GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://auth.zohar.no/application/o/authorize/";
      GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://auth.zohar.no/application/o/token/";
      GF_AUTH_GENERIC_OAUTH_API_URL = "https://auth.zohar.no/application/o/userinfo/";
      GF_AUTH_SIGNOUT_REDIRECT_URL = "https://auth.zohar.no/application/o/grafana/end-session/";
      GF_AUTH_OAUTH_AUTO_LOGIN = "true";
      GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "contains(entitlements[*], 'Grafana Admins') && 'Admin' || contains(entitlements[*], 'Grafana Editors') && 'Editor' || 'Viewer'";
    };
    serviceConfig = {
      EnvironmentFile = config.sops.secrets.grafana-env-file.path;
    };
  };
}
