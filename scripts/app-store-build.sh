set -e
git checkout app-store
git submodule update --init

echo 'checking OS'
if [ "$(uname)" == "Darwin" ]; then
    echo 'Mac OS X'
    sudo npm install -g n
    sudo n 7.9.0
    npm i -g yarn@0.22.0
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Do something under GNU/Linux platform
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    # Do something under 32 bits Windows NT platform
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    # Do something under 64 bits Windows NT platform
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
