# eGPU hotplug support: rescan the PCI bus when the eGPU is plugged in.
#
# This machine registers no native PCIe hotplug slots for its USB4 bridges
# (/sys/bus/pci/slots is empty, nothing is bound to pciehp), so when bolt
# authorizes the Thunderbolt router the PCIe tunnel is never enumerated and the
# GPU simply never appears. A manual `echo 1 > /sys/bus/pci/rescan` fixes it;
# this unit automates that.
#
# Chain: plug in -> bolt authorizes router -> udev (base-configuration.nix)
#        -> this unit rescans -> GPU enumerates at 07:00.0 (or 09:00.0 on the
#        other rear port) -> amdgpu binds -> SYMLINK+= creates
#        /dev/dri/amd-rx9070xt
#
# Nothing else is needed. Hyprland registers the eGPU as a secondary GPU on
# hotplug by itself -- AQ_DRM_DEVICES only constrains which GPU becomes
# *primary*, so with the iGPU pinned as primary the eGPU still gets picked up and
# its own DisplayPort output lights up directly. Games render on it via
# DRI_PRIME=pci-0000_07_00_0 (Steam launch option: `DRI_PRIME=pci-0000_07_00_0
# %command%`) and scan out with no copy back over Thunderbolt.
#
# Keeping the iGPU as primary is also the safer posture for hot-unplug: losing a
# secondary GPU is far more survivable for the compositor than losing the one it
# renders the desktop on.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.egpu-session;
in
{
  options.services.egpu-session = {
    enable = lib.mkEnableOption "PCI bus rescan on eGPU hotplug";

    pciId = lib.mkOption {
      type = lib.types.str;
      default = "1002:7550";
      description = ''
        PCI vendor:device ID of the eGPU, used to skip the rescan when the card is
        already enumerated. Must match the udev rules in base-configuration.nix.
      '';
    };

    primarySession = {
      enable = lib.mkEnableOption ''
        an extra "Hyprland (eGPU)" entry in the display manager that makes the
        eGPU the primary GPU, giving its outputs direct scanout
      '';

      devices = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "/dev/dri/amd-rx9070xt"
          "/dev/dri/amd-igpu"
        ];
        description = ''
          AQ_DRM_DEVICES list for the eGPU-primary session, most preferred first.
          The iGPU is kept as a fallback so the session still starts (on the
          laptop panel) if the eGPU is absent.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # A oneshot unit rather than udev RUN+= because udev kills long-running RUN
    # commands, and the settle delay plus rescan takes a few seconds.
    systemd.services.egpu-pci-rescan = {
      description = "Rescan PCI bus for hotplugged eGPU behind USB4 tunnel";

      # The udev rule fires for every authorized thunderbolt router, including the
      # two host routers present at boot. Without this the unit would complete
      # once at boot and systemd would treat later triggers as already satisfied,
      # so the real plug-in never rescans. Removing the rate limit also keeps
      # repeated plug/unplug cycles working.
      startLimitIntervalSec = 0;

      serviceConfig = {
        Type = "oneshot";
        # Nothing to do if the card is already on the bus; this turns the
        # boot-time host-router triggers into no-ops instead of consuming the
        # unit's single run.
        ExecCondition = "${pkgs.bash}/bin/bash -c '! ${pkgs.pciutils}/bin/lspci -nn | ${pkgs.gnugrep}/bin/grep -q ${cfg.pciId}'";
        # Settle first: bolt authorizes the router ~0.6s before the PCIe tunnel is
        # ready, and rescanning too early finds nothing.
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
        ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/pci/rescan'";
      };
    };

    # An extra display-manager entry that runs Hyprland with the eGPU as the
    # PRIMARY GPU. Compositing then happens on the eGPU, so its own DisplayPort
    # output scans out directly with no frame copy back over Thunderbolt -- worth
    # roughly 3x at 4K versus presenting through the iGPU.
    #
    # AQ_DRM_DEVICES has to be in the environment before the compositor execs
    # (aquamarine builds its DRM backend before Hyprland parses any config), and
    # environment.sessionVariables is global to every session on the host. Hence a
    # wrapper script with the value baked in, registered as its own session.
    #
    # Trade-off, deliberately not automated away: while this session is running the
    # eGPU is the GPU the desktop lives on, so unplugging it will very likely take
    # the session down. Use `egpu-teardown` first, or just use the normal
    # "Hyprland" session when you might unplug.
    services.displayManager.sessionPackages = lib.optional cfg.primarySession.enable (
      let
        launcher = pkgs.writeShellScript "start-hyprland-egpu" ''
          export AQ_DRM_DEVICES=${lib.concatStringsSep ":" cfg.primarySession.devices}
          exec ${config.programs.hyprland.package}/bin/start-hyprland "$@"
        '';
      in
      (pkgs.runCommand "hyprland-egpu-session" { } ''
        mkdir -p $out/share/wayland-sessions
        cat > $out/share/wayland-sessions/hyprland-egpu.desktop <<EOF
        [Desktop Entry]
        Name=Hyprland (eGPU primary)
        Comment=Hyprland with the external GPU as primary - direct scanout, no iGPU round trip
        Exec=${launcher}
        Type=Application
        DesktopNames=Hyprland
        Keywords=tiling;wayland;compositor;egpu;
        EOF
      '')
      // {
        # services.displayManager.sessionPackages requires this, and each name must
        # match a .desktop file the package provides or the build fails.
        providedSessions = [ "hyprland-egpu" ];
      }
    );
  };
}
