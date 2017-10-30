set -e
git checkout app-store
git submodule update --init

echo 'checking OS'
OSCheckError='Please run this script on Mac OS X.'
if [ "$(uname)" == "Darwin" ]; then
    echo 'Mac OS X'
    echo 'Installing node...'
    sudo npm install -g n
    sudo n 7.9.0
    echo 'Installing yarn...'
    npm i -g yarn@0.22.0
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo 'You are using GNU/Linux.'
    echo $OSCheckError
    exit 1
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
    echo 'You are using Windows 32 bit.'
    echo $OSCheckError
    exit 1
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
    echo 'You are using Windows 64 bit.'
    echo $OSCheckError
    exit 1
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
