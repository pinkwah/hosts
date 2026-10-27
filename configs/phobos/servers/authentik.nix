# https://wiki.nixos.org/wiki/Authentik
{
  config,
  pkgs,
  lib,
  ...
}:
let
  domain = "auth.zohar.no";
  stateDir = "/var/lib/authentik";

  serverHttpPort = 9500;
  serverMetricsPort = 9300;
  workerHttpPort = 9501;
  workerMetricsPort = 9301;

  commonEnvironment = {
    AUTHENTIK_POSTGRESQL__HOST = "/run/postgresql";
    AUTHENTIK_POSTGRESQL__NAME = "authentik";
    AUTHENTIK_POSTGRESQL__USER = "authentik";

    AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS = "127.0.0.0/8,::1/128";

    AUTHENTIK_STORAGE__FILE__PATH = stateDir;

    AUTHENTIK_SECRET_KEY = "file://${config.sops.secrets.authentik-secret.path}";

    AUTHENTIK_LOG_LEVEL = "info";
  };

  serverEnvironment = commonEnvironment // {
    AUTHENTIK_LISTEN__HTTP = "127.0.0.1:${toString serverHttpPort}";
    AUTHENTIK_LISTEN__METRICS = "127.0.0.1:${toString serverMetricsPort}";
  };

  workerEnvironment = commonEnvironment // {
    AUTHENTIK_LISTEN__HTTP = "127.0.0.1:${toString workerHttpPort}";
    AUTHENTIK_LISTEN__METRICS = "127.0.0.1:${toString workerMetricsPort}";
  };

  mkAuthentikSystemdService = role: environment: {
    description = "authentik ${role}";
    wantedBy = [ "multi-user.target" ];
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];

    inherit environment;

    preStart = ''
      ${config.services.postgresql.package}/bin/pg_isready -h /run/postgresql -d authentik -U authentik
    '';

    serviceConfig = {
      Type = "simple";
      User = "authentik";
      Group = "authentik";
      WorkingDirectory = stateDir;
      StateDirectory = "authentik";
      StateDirectoryMode = "0750";
      ExecStart = "${pkgs.authentik}/bin/ak ${role}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

in
{
  sops.secrets = {
    authentik-secret = {
      mode = "0400";
      path = "/etc/authentik-secret";
      owner = "authentik";
      group = "authentik";
    };
  };

  users = {
    groups.authentik = { };

    users.authentik = {
      isSystemUser = true;
      group = "authentik";
      home = stateDir;
    };
  };

  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ "authentik" ];
      ensureUsers = [
        {
          name = "authentik";
          ensureDBOwnership = true;
        }
      ];
      authentication = lib.mkAfter ''
        local authentik authentik peer
      '';
    };

    nginx.virtualHosts."${domain}" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString serverHttpPort}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };

  };

  systemd.services = {
    authentik-server = mkAuthentikSystemdService "server" serverEnvironment;
    authentik-worker = mkAuthentikSystemdService "worker" workerEnvironment;
  };
}
