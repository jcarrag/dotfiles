# relevant link https://github.com/NixOS/nixpkgs/issues/107648#issuecomment-765728045
# necessary until https://github.com/NixOS/nixpkgs/pull/110550 is in the channel
self: super:

{
  virtualbox = super.virtualbox.overrideAttrs (_: rec {
    version = "6.1.18";
    src = self.fetchurl {
      url = "https://download.virtualbox.org/virtualbox/${version}/VirtualBox-${version}.tar.bz2";
      sha256 = "108d42b9b391b7a332a33df1662cf7b0e9d9a80f3079d16288d8b9487f427d40";
    };
  });
  virtualboxExtpack = self.fetchurl {
    name = "Oracle_VM_VirtualBox_Extension_Pack-6.1.18.vbox-extpack";
    url = "https://download.virtualbox.org/virtualbox/6.1.18/Oracle_VM_VirtualBox_Extension_Pack-6.1.18.vbox-extpack";
    sha256 = "d609e35accff5c0819ca9be47de302abf094dc1b6d4c54da8fdda639671f267e";
  };
}
