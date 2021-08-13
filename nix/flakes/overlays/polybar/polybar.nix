self: super:

let
  config = self.pkgs.writeText "config.ini" ''
    ${builtins.readFile ./forest/bars.ini}

    ${builtins.readFile ./forest/colors.ini}
    
    ${builtins.readFile ./forest/modules.ini}

    ${builtins.readFile ./forest/user_modules.ini}

    ${builtins.readFile ./forest/config.ini}
  '';
in
{
  mypolybar = (
    super.pkgs.polybar.override {
      alsaSupport = true;
      githubSupport = true;
      mpdSupport = true;
      pulseSupport = true;
    }
  ).overrideAttrs (
    oldAttrs: {
      version = "3.5.6.1";
      src = self.pkgs.fetchFromGitHub {
        owner = oldAttrs.pname;
        repo = oldAttrs.pname;
        rev = "bfa9b5d53e72ea0ba4153cf171875ad7811cee21";
        sha256 = "sha256-yxUgaP02wt/2Qo26MUH3Cg5FBCHRjdXorDbdZQ1qS4Q=";
      };
      nativeBuildInputs = oldAttrs.nativeBuildInputs or [] ++ [ self.pkgs.makeWrapper ];
      postInstall = ''
        wrapProgram $out/bin/polybar \
          --add-flags "--config=${config}" \
          --add-flags "main" \
          --set XMONAD_LOG ${self.pkgs.xmonad-log}/bin/xmonad-log
      '';
    }
  );
}
