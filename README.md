# My-Wallet-iPhone-HD


# Building

## Add external dependencies

_ssh pub key has to be registered with Github for this to work_

    git clone git@github.com:blockchain/My-Wallet-HD.git External/My-Wallet-HD
    git clone git@github.com:x2on/OpenSSL-for-iPhone.git External/OpenSSL

Prepare the MyWallet Javascript:

    cd External/My-Wallet
    npm install
    grunt build

Prepare OpenSSL:

    cd External/OpenSSL
    ./build-libssl.sh

## Open the project in Xcode

    open Blockchain.xcodeproj

## Build the project

    cmd-r

## PSD and Asset Catalog

Images.xcassets contains all images the app needs and they are all included in the repository.

You can optionally generate the PNG files from the PSD sources in /Artwork. This requires ImageMagick and Grunt. If the PSD files change then this step is required. The resulting new PNG files should be commited to Git to make life easier for other developers.

Once:

    npm install -g grunt-cli
    cd Artwork
    npm install    
  
For each change:
  
    grunt

## License

Source Code License: LGPL v3

Artwork & images remain Copyright Ben Reeves - Qkos Services Ltd 2012-2014
