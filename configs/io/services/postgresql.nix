{ ... }:

{
  services.postgresql = {
    enable = true;
  };

  services.borgmatic = {
    configurations.default = {
      postgresql_databases = [
        {
          name = "all";
        }
      ];
    };
  };
}
