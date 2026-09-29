{
  config,
  lib,
  pkgs,
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
    systemd.user.services.sunshine.serviceConfig.ExecStartPre = pkgs.tailscaleWaitOnline;
    services.sunshine = {
      enable = true;
      capSysAdmin = true;
      settings = {
        # https://github.com/LizardByte/Sunshine/pull/4481
        bind_address = cfg.bindAddress;
        encoder = "vaapi";
        adapter_name = cfg.adapterName;
        csrf_allowed_origins = "https://100.114.72.23,https://100.65.97.33,https://100.124.115.79,https://100.102.227.124,https://100.91.170.36,https://100.100.51.100,https://100.108.41.69";
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
