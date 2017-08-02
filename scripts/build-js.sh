set -ue
cd Submodules/My-Wallet-V3

git log -1 | cat

echo "Cleaning..."
rm -rf build dist

echo "Building..."
grunt build --base .

# Required for JavaScriptCore

echo "Disabling rng for uuid..."
functionWhatwgRNG='function whatwgRNG() {'
sed -i '' 's/rng = '"$functionWhatwgRNG"'/var discard = '"$functionWhatwgRNG"'/' dist/my-wallet.js

echo "Overriding uuid..."
sed -i '' 's/uuid()/MyWalletPhone.nsuuid()/g' dist/my-wallet.js

echo "Patching global.crypto..."
globalCrypto='global.crypto || global.msCrypto'
sed -i '' 's/'"$globalCrypto"'\;/global.crypto = '"$globalCrypto"' || objcCrypto(Buffer)/' dist/my-wallet.js

# Required for overriding methods in Objective-C
echo "Patching BitcoinJS..."
sed -i '' '/validateMnemonic: validateMnemonic/s/$/, salt: salt/' dist/my-wallet.js

echo "Build success"
