set -ue
cd Submodules/My-Wallet-V3

git log -1 | cat

echo "Cleaning node_modules..."
rm -rf node_modules

echo "Installing node_modules..."
make node_modules

echo "Installing Grunt plugins..."
npm install grunt@1.0.1 grunt-browserify@5.0.0 grunt-text-replace@0.4.0 babelify@7.3.0 babel-preset-es2015@6.24.1 babel-plugin-transform-object-assign@6.22.0

# Required for JavaScriptCore
echo "Patching fetch..."
sed -i '' '1s/^/global.self = global;/' node_modules/whatwg-fetch/fetch.js

echo "Install success"
