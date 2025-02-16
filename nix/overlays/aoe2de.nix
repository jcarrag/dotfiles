self: super:

{
  aoe-2-de = self.pkgs.writeTextDir "share/applications/aoe-de-2.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Age of Empires II: Definitive Edition
    Exec=${self.pkgs.steam}/bin/steam -applaunch 813780 %u
    MimeType=x-scheme-handler/aoe2de;
  '';
}
