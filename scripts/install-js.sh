cd Submodules/My-Wallet-V3

echo "Cleaning node_modules..."
rm -rf node_modules

echo "Installing node_modules..."
npm install || exit 1

# Required for JavaScriptCore
echo "Patching fetch..."
sed -i '' '1s/^/global.self = global;/' node_modules/whatwg-fetch/fetch.js

echo "Install success"
