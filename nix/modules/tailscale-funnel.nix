{ lib, pkgs, config, ... }:

with lib; with lib.types;
let
  cfg = config.programs.tailscale-funnel;
in
{
  options.programs.tailscale-funnel = {
    port = mkOption {
      type = types.port;
      default = 443;
      description = lib.mdDoc "The port at which this Tailscale Funnel is listening.";
    };

    services = mkOption
      {
        description = "The definition of the Tailscale Funnel.";
        type = types.attrsOf
          (types.submodule {
            options = {
              enable = mkEnableOption "proxying this service via Tailscale Funnel.";

              port = mkOption {
                type = types.port;
                description = lib.mdDoc "The port at which this service is listening.";
              };

              path = mkOption {
                type = types.str;
                description = lib.mdDoc "The URL path at which this service will be proxied.";
              };
            };
          });
      };
  };

  config =
    let
      enabled = lib.attrsets.filterAttrs (n: v: v.enable) cfg.services;
      enabledNames = builtins.map (name: "tailscale-funnel-${name}.service") (builtins.attrNames enabled);
      anyEnabled = enabled != [ ];
    in
    lib.attrsets.recursiveUpdate
      {
        systemd.services = lib.attrsets.mapAttrs'
          (name: { enable, port, path }:
            let
              start = "${pkgs.unstable.tailscale}/bin/tailscale funnel --bg --https ${builtins.toString cfg.port} --set-path=${path} localhost:${builtins.toString port}";
              stop = "${start} off";
            in
            lib.attrsets.nameValuePair
              "tailscale-funnel-${name}"
              {
                description = "Tailscale Funnel forwarding for ${name}";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];

                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = start;
                  ExecStop = stop;
                  # ExecStopPost = "${pkgs.systemd}/bin/systemctl restart tailscaled.service";
                  Restart = "on-failure";
                };
              }
          )
          enabled;
      }
      # (if anyEnabled then
      {
        # systemd.services.tailscaled.serviceConfig.PartOf = lib.debug.traceValSeq enabledNames;
      };
  # else
  #   { }
  # );
}
