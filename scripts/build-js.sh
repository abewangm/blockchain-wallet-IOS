set -ue
cd Submodules/My-Wallet-V3

git log -1 | cat

echo "Cleaning..."
rm -rf build dist

echo "Building..."
grunt build --base .

# Required for overriding methods in Objective-C
echo "Patching BitcoinJS..."
sed -i '' '/validateMnemonic: validateMnemonic/s/$/, salt: salt/' dist/my-wallet.js

echo "Build success"
