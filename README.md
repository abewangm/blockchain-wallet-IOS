# My-Wallet-iPhone-HD


# Building

## Setup git submodules

_ssh pub key has to be registered with Github for this to work_

    git submodule update --init
    cd Submodules/My-Wallet-HD
    npm install
    grunt build
    cd ../OpenSSL-for-iPhone  
    ./build-libssl.sh

## Open the project in Xcode

    cd ../../
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
