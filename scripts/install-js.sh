set -ue
cd Submodules/My-Wallet-V3

command -v yarn >/dev/null 2>&1 || {
  echo >&2 "yarn required to run install script";
  echo >&2 "install: npm i -g yarn";
  exit 1;
}

echo "Cleaning node_modules..."
rm -rf node_modules

echo "Installing node_modules..."
yarn install --ignore-engines

# Required for JavaScriptCore
echo "Patching fetch..."
sed -i '' '1s/^/global.self = global;/' node_modules/whatwg-fetch/fetch.js

echo "Install success"
