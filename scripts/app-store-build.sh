set -e
git checkout app-store
git submodule update --init
sh scripts/install-js.sh
sh scripts/build-js.sh
cd Submodules/OpenSSL-for-iPhone/
./build-libssl.sh
cd ../.. && sh scripts/update-certs.sh
npm install -g grunt-cli
cd Artwork
npm install
npm -g install svgexport
grunt
cd ../
open Blockchain.xcodeproj
