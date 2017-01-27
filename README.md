# My-Wallet-V3-iOS


# Building

## Setup git submodules

Prepare SocketRocket:

    git submodule update --init

Prepare the MyWallet Javascript:

    cd Submodules/My-Wallet-V3
    npm install
    // Required for JavaScriptCore
    sed -i '' '1s/^/global.self = global;/' node_modules/whatwg-fetch/fetch.js
    grunt build
    // Required for JavaScriptCore
    grunt build && globalCrypto='var crypto = global.crypto || global.msCrypto' && sed -i '' 's/'"$globalCrypto"'\;/'"$globalCrypto"' || {getRandomValues: function(){}}/' dist/my-wallet.js
    // Required for overriding methods in Objective-C
    sed -i '' '/validateMnemonic: validateMnemonic/s/$/, salt: salt/' dist/my-wallet.js

Prepare OpenSSL:

    cd ../OpenSSL-for-iPhone  
    ./build-libssl.sh

## PSD and Asset Catalog

Images.xcassets contains all images the app needs, but they must be generated first from the PSD sources in /Artwork. This requires ImageMagick and Grunt.

Install ImageMagic, e.g. with [Homebrew](http://brew.sh):

    brew install imagemagick

Once:

    npm install -g grunt-cli
    cd Artwork
    npm install
    npm install -g svgexport
 
Whenever you change a PSD or SVG file, run: 
  
    grunt

The reason that the PNG files are not in the repository - even though it would make life easier for other developers - is that the resulting PNG files are not deterministic. This causes git to mark all images as changed every time you run Grunt. 

## Open the project in Xcode

    open Blockchain.xcodeproj

## Build the project

    cmd-r


## License

Source Code License: LGPL v3

Artwork & images remain Copyright Blockchain Luxembourg S.A.R.L

## Security

Security issues can be reported to us in the following venues:
* Email: security@blockchain.info
* Bug Bounty: https://www.crowdcurity.com/blockchain-info

