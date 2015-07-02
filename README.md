# My-Wallet-iPhone-HD


# Building

## Add external dependencies

_ssh pub key has to be registered with Github for this to work_

    git clone git@github.com:blockchain/My-Wallet-HD.git External/My-Wallet-HD
    git clone git@github.com:x2on/OpenSSL-for-iPhone.git External/OpenSSL

Prepare the MyWallet Javascript:

    cd External/My-Wallet-HD
    npm install
    grunt build

Prepare OpenSSL:

    cd External/OpenSSL
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

The reason that the PNG files are not in the repository - even though it woud make life easier for other developers - is that the resuling PNG files are not determistic. This causes git to mark all images as changed every time you run Grunt. 

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

