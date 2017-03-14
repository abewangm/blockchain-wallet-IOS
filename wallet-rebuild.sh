#! /usr/bin/env sh
cd Submodules/My-Wallet-V3
## Required for JavaScriptCore
sed -i '' '1s/^/global.self = global;/' node_modules/whatwg-fetch/fetch.js
## Required for JavaScriptCore
grunt build && globalCrypto='var crypto = global.crypto || global.msCrypto' && sed -i '' 's/'"$globalCrypto"'\;/'"$globalCrypto"' || objcCrypto(Buffer)/' dist/my-wallet.js
## Required for overriding methods in Objective-C
sed -i '' '/validateMnemonic: validateMnemonic/s/$/, salt: salt/' dist/my-wallet.js
