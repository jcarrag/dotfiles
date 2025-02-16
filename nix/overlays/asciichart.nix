self: super:

{
  asciicharts =
    with super;
    stdenv.mkDerivation rec {
      pname = "asciichart";
      version = "1.0.0";

      src = fetchFromGitHub {
        owner = "kroitor";
        repo = "asciichart";
        rev = "ef1141b210b55fbb7742846ff2fe87d158e76fd2";
        sha256 = "x9wx0rEYYDTbF4TAuVlMwOHEOE9hKlH1TxJpcZO9qXw=";
      };

      buildInputs = [ nodejs ];

      installPhase = ''
        mkdir -p $out/bin
        mkdir $out/asciichart

        cp -r * $out/asciichart

        touch $out/bin/asciichart
        chmod +x $out/bin/asciichart

        cat <<EOF >> $out/bin/asciichart
        #!${pkgs.nodejs}/bin/node

        const asciichart = require("$out/asciichart");
        const readline = require('readline');

        const colors = [
          asciichart.blue,
          asciichart.green,
          asciichart.red,
          asciichart.magenta,
          asciichart.yellow,
          asciichart.cyan,
          asciichart.darkgray,
          asciichart.white,
          asciichart.lightred,
          asciichart.lightgreen,
          asciichart.lightyellow,
          asciichart.lightblue,
          asciichart.lightmagenta,
          asciichart.lightcyan,
          asciichart.lightgray,
        ];

        const rl = readline.createInterface({
          input: process.stdin,
          output: process.stdout
        });

        const config = {
            height: process.stdout.rows - 5,
            colors,
        };

        const maxLength = process.stdout.columns - 15;

        var numbers = [];

        rl.on('line', (inputS) => {
          const input = JSON.parse(inputS);

          console.log(`Received: ''${JSON.stringify(input)}`);

          if (numbers.length == 0) {
            numbers = input.map(n => [n]);
          } else {
            numbers.forEach((n, i) => {
              if(n.length >= maxLength) n.shift();

              n.push(input[i]);
            });
          }

          console.clear();
          console.log(asciichart.plot (numbers, config));
        });
        EOF
      '';
    };
}
