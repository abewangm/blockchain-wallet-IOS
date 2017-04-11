cd Submodules/My-Wallet-V3

echo "Cleaning..."
rm -rf build dist

echo "Building..."
grunt build

# Required for JavaScriptCore
echo "Patching global.crypto..."
globalCrypto='var crypto = global.crypto || global.msCrypto'
sed -i '' 's/'"$globalCrypto"'\;/'"$globalCrypto"' || objcCrypto(Buffer)/' dist/my-wallet.js

# Required for overriding methods in Objective-C
echo "Patching BitcoinJS..."
sed -i '' '/validateMnemonic: validateMnemonic/s/$/, salt: salt/' dist/my-wallet.js

echo "Build success"
