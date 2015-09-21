# My-Wallet-V3-iOS


# Building

## Setup git submodules

_ssh pub key has to be registered with Github for this to work_

    git clone git@github.com:blockchain/My-Wallet-V3.git Submodules/My-Wallet-V3
    git clone git@github.com:x2on/OpenSSL-for-iPhone.git Submodules/OpenSSL-for-iPhone

Prepare the MyWallet Javascript:

    git submodule update --init
    cd Submodules/My-Wallet-V3
    npm install
    grunt build

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

Artwork & images remain Copyright Ben Reeves - Qkos Services Ltd 2012-2014

## Security

Security issues can be reported to us in the following venues:
* Email: security@blockchain.info
* Bug Bounty: https://www.crowdcurity.com/blockchain-info

