{ lib, pkgs, config, ... }:

with lib; with lib.types;
let
  cfg = config.programs.taffybar-my;
in
{
  options.programs.taffybar-my = {
    enable = mkEnableOption "Enable the taffybar service.";
  };

  config = mkIf cfg.enable (
    {
      # haskell kernel bug: https://discourse.haskell.org/t/facing-mmap-4096-bytes-at-nil-cannot-allocate-memory-youre-not-alone/6259
      # suggested patch: https://bbs.archlinux.org/viewtopic.php?pid=2100343#p2100343
      boot.kernelPatches = [{
        name = "haskell-mmap-fix";
        patch = builtins.fetchurl
          {
            url = "https://git.kernel.org/pub/scm/linux/kernel/git/akpm/mm.git/patch/?id=0257d9908d38c0b1669af4bb1bc4dbca1f273fe6";
            sha256 = "00m8rh121x5bdr07gg9bfj45004f69cp9xhx3fpl88xkj95bc59n";
          };
      }];

      environment.systemPackages = [
        pkgs.taffybar-my
      ];

      systemd.user.services.taffybar-my = {
        description = "Taffybar(-my)";
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        restartTriggers = [ pkgs.taffybar-my ];
        startLimitIntervalSec = 30;
        startLimitBurst = 2;

        serviceConfig = {
          ExecStart = "${pkgs.taffybar-my}/bin/taffybar-my";
          Restart = "always";
        };
      };
    }
  );
}
