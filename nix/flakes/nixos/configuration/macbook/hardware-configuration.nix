# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/1e084baa-69f4-4d23-a187-0524c94814cf";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/6360-69ED";
      fsType = "vfat";
    };

  swapDevices =
    [
      { device = "/dev/disk/by-uuid/e76e7a63-b917-486b-bb77-f205625b872d"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
