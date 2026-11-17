{ pkgs, ... }:

# Profile auto-switch for LE Audio (BAP) Bluetooth headsets, e.g. Sony INZONE H9 II.
#
# Such headsets only expose bap-* profiles. WirePlumber only creates the
# placeholder mic source that drives bluetooth.autoswitch-to-headset-profile
# for cards with a classic "headset" profile, so a BAP-only card never switches.
# Treat bap-duplex the same: the card then sits on bap-sink (good playback) and
# flips to bap-duplex only while something records from the headset mic.
#
# Needs hardware.bluetooth.settings.General.KernelExperimental (ISO sockets),
# set in base-configuration.nix.
{
  # --replace-fail makes the build fail loudly if upstream moves this code
  # (it lives in monitors/bluez/create-loopback-node.lua from 0.5.19 at the latest).
  services.pipewire.wireplumber.package = pkgs.wireplumber.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/scripts/monitors/bluez.lua \
        --replace-fail 'if profile.name:find ("headset") then' \
                       'if profile.name:find ("headset") or profile.name == "bap-duplex" then'
    '';
  });
}
