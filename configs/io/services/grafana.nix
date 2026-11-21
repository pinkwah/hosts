{ config, ... }:

let

  domain = "io.hosts.zohar.no";
  subpath = "/grafana";
  http_addr = "127.0.0.1";
  http_port = 8100;

in
{
  environment.etc."alloy/config.alloy" = {
    enable = true;
    user = "alloy";
    group = "alloy";
    text = ''
      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label = "unit"
        }

        rule {
          source_labels = ["__journal__priority_keyword"]
          target_label = "priority"
        }

        rule {
          source_labels = ["__journal__hostname"]
          target_label = "hostname"
        }
      }

      loki.source.journal "host" {
        path = "/var/log/journal"
        max_age = "12h"
        relabel_rules = loki.relabel.journal.rules
        labels = { job = "systemd-journal" }
        forward_to = [loki.process.journal.receiver]
      }

      loki.process "journal" {
        // Drop high-volume units that rarely carry actionable signal in a
        // generic dev/ops dashboard. Tune this list to your environment.
        stage.match {
        	selector = `{unit=~"systemd-logind.service|systemd-tmpfiles-clean.service|cron.service"}`
        	action   = "drop"
        }

        // Drop low-priority entries (info / debug). Keep notice and above.
        // Adjust if you want to keep info messages.
        stage.match {
        	selector = `{priority=~"info|debug"}`
        	action   = "drop"
        }

        forward_to = [loki.write.local.receiver]
      }

      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:3100/loki/api/v1/push"
        }
      }
    '';
  };

  users.groups.alloy.members = [
    "adm"
    "systemd-journal"
  ];

  services = {
    alloy = {
      enable = true;
    };

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
