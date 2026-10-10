{
  config,
  pkgs,
  inputs,
  ...
}:
let

  system = pkgs.stdenv.hostPlatform.system;
  memos = inputs.nixpkgs-unstable.legacyPackages."${system}".memos;

in
{
  services = {
    memos = {
      enable = true;
      package = memos;
      settings = {
        MEMOS_MODE = "prod";
        MEMOS_PORT = "5230";
        MEMOS_INSTANCE_URL = "https://wah.pink/memos";
        MEMOS_DATA = config.services.memos.dataDir;
      };
    };

    nginx.virtualHosts."memos.wah.pink" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://[::1]:${config.services.memos.settings.MEMOS_PORT}/";
      };
    };
  };
}
