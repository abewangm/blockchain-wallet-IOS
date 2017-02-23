# My-Wallet-V3-iOS


# Building

## Setup git submodules

Prepare SocketRocket:

    git submodule update --init

Build JavaScript dependencies:

    npm install
    cd Submodules/My-Wallet-V3 && npm install
    cd ../..
    npm run build

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

## Development

Build project: `cmd-r`

Watch JS dependencies for changes: `npm run build:watch`

While `build:watch` is active, you may edit My-Wallet-V3 source code in Submodules, and the changes will be automatically be reflected in the next build.

## License

Source Code License: LGPL v3

Artwork & images remain Copyright Blockchain Luxembourg S.A.R.L

## Security

Security issues can be reported to us in the following venues:
* Email: security@blockchain.info
* Bug Bounty: https://www.crowdcurity.com/blockchain-info

