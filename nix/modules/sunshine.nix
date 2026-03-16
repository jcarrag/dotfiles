{
  config,
  lib,
  ...
}:

let
  cfg = config.services._sunshine;
in
{
  options.services = with lib; {
    _sunshine = {
      enable = mkEnableOption "_sunshine";
      bindAddress = mkOption {
        type = types.str;
      };
      adapterName = mkOption {
        type = types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      settings = {
        # https://github.com/LizardByte/Sunshine/pull/4481
        bind_address = cfg.bindAddress;
        encoder = "vaapi";
        adapter_name = cfg.adapterName;
      };
    };
    networking.firewall.interfaces.tailscale0 = {
      allowedTCPPortRanges = [
        {
          from = 47984;
          to = 48010;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 47998;
          to = 48010;
        }
      ];
    };
  };
}
