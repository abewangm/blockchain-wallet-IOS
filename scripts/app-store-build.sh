set -e
git checkout app-store
git submodule update --init

echo 'checking OS'
if [ "$(uname)" == "Darwin" ]; then
    echo 'Mac OS X'
    echo 'Installing node...'
    sudo npm install -g n
    sudo n 7.9.0
    echo 'Installing yarn...'
    npm i -g yarn@0.22.0
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo 'GNU/Linux'
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    echo 'Windows 32 bit'
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    echo 'Windows 64 bit'
fi

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
