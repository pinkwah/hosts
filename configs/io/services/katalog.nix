{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  name = "webapp-katalog";

  cfg = {
    enable = true;
    configureNginx = true;
    user = name;
    group = name;

    webPort = 55001;
    webProcesses = 2;
    webThreads = 5;
    # sidekiqPort = 55002;
    # sidekiqThreads = 25;
    # sidekiqProcesses = {
    #   all = {
    #     jobClasses = [ ];
    #     threads = null;
    #   };
    # };

    vapidPublicKeyFile = "/var/lib/${name}/secrets/vapid-public-key";
    vapidPrivateKeyFile = "/var/lib/${name}/secrets/vapid-private-key";

    localDomain = "katalog.wah.pink";
    activeRecordEncryptionDeterministicKeyFile = "/var/lib/${name}/secrets/active-record-encryption-deterministic-key";
    activeRecordEncryptionKeyDerivationSaltFile = "/var/lib/${name}/secrets/active-record-encryption-key-derivation-salt";
    activeRecordEncryptionPrimaryKeyFile = "/var/lib/${name}/secrets/active-record-encryption-primary-key";
    secretKeyBaseFile = "/var/lib/${name}/secrets/secret-key-base";
    trustedProxy = "127.0.0.1";
    enableUnixSocket = false;

    redis = {
      createLocally = true;
      host = if cfg.redis.createLocally && !cfg.redis.enableUnixSocket then "127.0.0.1" else null;
      port = if cfg.redis.createLocally && !cfg.redis.enableUnixSocket then 31637 else null;
      passwordFile = null;
      enableUnixSocket = true;
    };

    database = {
      createLocally = true;
      host = "/run/postgresql";
      port = if cfg.database.createLocally then null else 5432;
      name = name;
      user = name;
      passwordFile = null;
    };

    smtp = {
      createLocally = true;
      authenticate = false;
      host = "127.0.0.1";
      port = 25;
      fromAddress = "test@zohar.no";

      user = null;
      passwordFile = null;
    };

    package = inputs.katalog.packages.${system}.default;

    extraConfig = { };
    extraEnvFiles = [ ];
    automaticMigrations = true;
  };

  # We only want to create a Redis and PostgreSQL databases if we're actually going to connect to it local.
  redisActuallyCreateLocally =
    cfg.redis.createLocally && (cfg.redis.host == "127.0.0.1" || cfg.redis.enableUnixSocket);
  databaseActuallyCreateLocally =
    cfg.database.createLocally && cfg.database.host == "/run/postgresql";

  env = {
    RAILS_ENV = "production";
    NODE_ENV = "production";

    BOOTSNAP_CACHE_DIR = "/var/cache/${name}/precompile";
    LD_PRELOAD = "${pkgs.jemalloc}/lib/libjemalloc.so";

    WEB_CONCURRENCY = toString cfg.webProcesses;
    MAX_THREADS = toString cfg.webThreads;

    DATABASE_URL = "sqlite3:/var/lib/${name}/database.sqlite3";
    CACHE_DATABASE_URL = "sqlite3:/var/lib/${name}/cache.sqlite3";
    QUEUE_DATABASE_URL = "sqlite3:/var/lib/${name}/queue.sqlite3";
    CABLE_DATABASE_URL = "sqlite3:/var/lib/${name}/cable.sqlite3";

    LOCAL_DOMAIN = cfg.localDomain;
    PAPERCLIP_ROOT_PATH = "/var/lib/${name}/public-system";
    PAPERCLIP_ROOT_URL = "/system";

    TRUSTED_PROXY_IP = cfg.trustedProxy;
  }
  // lib.optionalAttrs (cfg.database.host != "/run/postgresql" && cfg.database.port != null) {
    DB_PORT = toString cfg.database.port;
  }
  // cfg.extraConfig;

  systemCallsList = [
    "@cpu-emulation"
    "@debug"
    "@keyring"
    "@ipc"
    "@mount"
    "@obsolete"
    "@privileged"
    "@setuid"
  ];

  cfgService = {
    # User and group
    User = cfg.user;
    Group = cfg.group;
    # Working directory
    WorkingDirectory = cfg.package;
    # Cache directory and mode
    CacheDirectory = name;
    CacheDirectoryMode = "0750";
    # State directory and mode
    StateDirectory = name;
    StateDirectoryMode = "0750";
    # Logs directory and mode
    LogsDirectory = name;
    LogsDirectoryMode = "0750";
    # Proc filesystem
    ProcSubset = "pid";
    ProtectProc = "invisible";
    # Access write directories
    UMask = "0027";
    # Capabilities
    CapabilityBoundingSet = "";
    # Security
    NoNewPrivileges = true;
    # Sandboxing
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK"
    ];
    RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = false;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    PrivateMounts = true;
    # System Call Filtering
    SystemCallArchitectures = "native";
  };

  commonUnits =
    lib.optional databaseActuallyCreateLocally "postgresql.target"
    ++ lib.optional cfg.automaticMigrations "${name}-init-db.service";

  # sidekiqUnits = lib.attrsets.mapAttrs' (
  #   name': processCfg:
  #   lib.nameValuePair "${name}-sidekiq-${name'}" (
  #     let
  #       jobClassArgs = toString (map (c: "-q ${c}") processCfg.jobClasses);
  #       jobClassLabel = toString ([ "" ] ++ processCfg.jobClasses);
  #       threads = toString (if processCfg.threads == null then cfg.sidekiqThreads else processCfg.threads);
  #     in
  #     {
  #       after = [
  #         "network.target"
  #         "${name}-init-dirs.service"
  #       ]
  #       ++ commonUnits;
  #       requires = [ "${name}-init-dirs.service" ] ++ commonUnits;
  #       description = "${name} sidekiq${jobClassLabel}";
  #       wantedBy = [ "${name}.target" ];
  #       environment = env // {
  #         PORT = toString cfg.sidekiqPort;
  #         DB_POOL = threads;
  #       };
  #       serviceConfig = {
  #         ExecStart = "${cfg.package}/bin/sidekiq ${jobClassArgs} -c ${threads} -r ${cfg.package}";
  #         Restart = "always";
  #         RestartSec = 20;
  #         EnvironmentFile = [ "/var/lib/${name}/.secrets_env" ] ++ cfg.extraEnvFiles;
  #         WorkingDirectory = cfg.package;
  #         LimitNOFILE = "1024000";
  #         # System Call Filtering
  #         SystemCallFilter = [
  #           ("~" + lib.concatStringsSep " " systemCallsList)
  #           "@chown"
  #           "pipe"
  #           "pipe2"
  #         ];
  #       }
  #       // cfgService;
  #       path = with pkgs; [
  #         ffmpeg-headless
  #         file
  #       ];
  #     }
  #   )
  # ) cfg.sidekiqProcesses;

in
lib.mkMerge [
  {
    systemd.targets.${name} = {
      description = "Target for all ${name} services";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
    };

    systemd.services."${name}-init-dirs" = {
      script = ''
        set +x
        umask 077

        if ! test -d /var/cache/${name}/precompile; then
          ${cfg.package}/bin/bundle exec bootsnap precompile --gemfile ${cfg.package}/app ${cfg.package}/lib
        fi
        if ! test -f ${cfg.activeRecordEncryptionDeterministicKeyFile}; then
          mkdir -p $(dirname ${cfg.activeRecordEncryptionDeterministicKeyFile})
          bin/rails db:encryption:init | grep --only-matching "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=[^ ]\+" | sed 's/^ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=//' > ${cfg.activeRecordEncryptionDeterministicKeyFile}
        fi
        if ! test -f ${cfg.activeRecordEncryptionKeyDerivationSaltFile}; then
          mkdir -p $(dirname ${cfg.activeRecordEncryptionKeyDerivationSaltFile})
          bin/rails db:encryption:init | grep --only-matching "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=[^ ]\+" | sed 's/^ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=//' > ${cfg.activeRecordEncryptionKeyDerivationSaltFile}
        fi
        if ! test -f ${cfg.activeRecordEncryptionPrimaryKeyFile}; then
          mkdir -p $(dirname ${cfg.activeRecordEncryptionPrimaryKeyFile})
          bin/rails db:encryption:init | grep --only-matching "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=[^ ]\+" | sed 's/^ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=//' > ${cfg.activeRecordEncryptionPrimaryKeyFile}
        fi
        if ! test -f ${cfg.secretKeyBaseFile}; then
          mkdir -p $(dirname ${cfg.secretKeyBaseFile})
          bin/bundle exec rails secret > ${cfg.secretKeyBaseFile}
        fi

        cat > /var/lib/${name}/.secrets_env <<-EOF
        ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="$(cat ${cfg.activeRecordEncryptionDeterministicKeyFile})"
        ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="$(cat ${cfg.activeRecordEncryptionKeyDerivationSaltFile})"
        ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="$(cat ${cfg.activeRecordEncryptionPrimaryKeyFile})"
        SECRET_KEY_BASE="$(cat ${cfg.secretKeyBaseFile})"
        VAPID_PRIVATE_KEY="$(cat ${cfg.vapidPrivateKeyFile})"
        VAPID_PUBLIC_KEY="$(cat ${cfg.vapidPublicKeyFile})"
      ''
      + lib.optionalString (cfg.redis.passwordFile != null) ''
        REDIS_PASSWORD="$(cat ${cfg.redis.passwordFile})"
      ''
      + lib.optionalString (cfg.database.passwordFile != null) ''
        DB_PASS="$(cat ${cfg.database.passwordFile})"
      ''
      + lib.optionalString cfg.smtp.authenticate ''
        SMTP_PASSWORD="$(cat ${cfg.smtp.passwordFile})"
      ''
      + ''
        EOF
      '';
      environment = env;
      serviceConfig = {
        Type = "oneshot";
        SyslogIdentifier = "${name}-init-dirs";
        # System Call Filtering
        SystemCallFilter = [
          ("~" + lib.concatStringsSep " " (systemCallsList ++ [ "@resources" ]))
          "@chown"
          "pipe"
          "pipe2"
        ];
      }
      // cfgService;

      after = [ "network.target" ];
    };

    systemd.services."${name}-init-db" = lib.mkIf cfg.automaticMigrations {
      script = ''
        echo "Migrating database (this might be a noop)"
        rails db:prepare
      '';
      path = [
        cfg.package
        (if databaseActuallyCreateLocally then config.services.postgresql.package else pkgs.postgresql)
      ];
      environment = env;
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = [ "/var/lib/${name}/.secrets_env" ] ++ cfg.extraEnvFiles;
        WorkingDirectory = cfg.package;
        # System Call Filtering
        SystemCallFilter = [
          ("~" + lib.concatStringsSep " " (systemCallsList ++ [ "@resources" ]))
          "@chown"
          "pipe"
          "pipe2"
        ];
      }
      // cfgService;
      after = [
        "network.target"
        "${name}-init-dirs.service"
      ]
      ++ lib.optional databaseActuallyCreateLocally "postgresql.target";
      requires = [
        "${name}-init-dirs.service"
      ]
      ++ lib.optional databaseActuallyCreateLocally "postgresql.target";
    };

    systemd.services."${name}-web" = {
      after = [
        "network.target"
        "${name}-init-dirs.service"
      ]
      ++ commonUnits;
      requires = [ "${name}-init-dirs.service" ] ++ commonUnits;
      wantedBy = [ "${name}.target" ];
      description = "${name} web";
      environment =
        env
        // (
          if cfg.enableUnixSocket then
            { SOCKET = "/run/${name}/rails.sock"; }
          else
            { PORT = toString cfg.webPort; }
        );
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/puma -C config/puma.rb";
        Restart = "always";
        RestartSec = 20;
        EnvironmentFile = [ "/var/lib/${name}/.secrets_env" ] ++ cfg.extraEnvFiles;
        WorkingDirectory = cfg.package;
        # Runtime directory and mode
        RuntimeDirectory = "${name}-web";
        RuntimeDirectoryMode = "0750";
        # System Call Filtering
        SystemCallFilter = [
          ("~" + lib.concatStringsSep " " systemCallsList)
          "@chown"
          "pipe"
          "pipe2"
        ];
      }
      // cfgService;
      path = with pkgs; [
        ffmpeg-headless
        file
      ];
    };

    services.nginx = lib.mkIf cfg.configureNginx {
      enable = true;
      recommendedProxySettings = true; # required for redirections to work
      virtualHosts."${cfg.localDomain}" = {
        root = "${cfg.package}/public/";
        forceSSL = lib.mkDefault true;
        enableACME = lib.mkDefault true;

        locations."/system/".alias = "/var/lib/${name}/public-system/";

        locations."/" = {
          tryFiles = "$uri @proxy";
        };

        locations."@proxy" = {
          proxyPass = (
            if cfg.enableUnixSocket then
              "http://unix:/run/${name}/rails.sock"
            else
              "http://127.0.0.1:${toString cfg.webPort}"
          );
          proxyWebsockets = true;
        };
      };
    };

    services.postfix = lib.mkIf (cfg.smtp.createLocally && cfg.smtp.host == "127.0.0.1") {
      enable = true;
      settings.main.myhostname = lib.mkDefault "${cfg.localDomain}";
    };

    services.redis.servers.${name} = lib.mkIf redisActuallyCreateLocally (
      lib.mkMerge [
        {
          enable = true;
        }
        (lib.mkIf (!cfg.redis.enableUnixSocket) {
          port = cfg.redis.port;
        })
      ]
    );

    services.postgresql = lib.mkIf databaseActuallyCreateLocally {
      enable = true;
      ensureUsers = [
        {
          name = cfg.database.name;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ cfg.database.name ];
    };

    users.users = lib.mkMerge [
      (lib.mkIf (cfg.user == name) {
        ${name} = {
          isSystemUser = true;
          home = "/var/lib/${cfg.user}";
          inherit (cfg) group;
        };
      })
      (lib.attrsets.setAttrByPath [ cfg.user "packages" ] [ cfg.package ])
      (lib.mkIf (cfg.redis.createLocally && cfg.redis.enableUnixSocket) {
        ${cfg.user}.extraGroups = [ "redis-${name}" ];
      })
    ];

    users.groups.${cfg.group}.members = lib.optional cfg.configureNginx config.services.nginx.user;
  }
  {
    # systemd.services = lib.mkMerge [
    #   sidekiqUnits
    # ];
  }
]
