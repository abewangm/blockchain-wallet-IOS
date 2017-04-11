set -ue
command -v nodemon >/dev/null 2>&1 || {
  echo >&2 "nodemon required to run watch-js script";
  echo >&2 "install: npm i -g nodemon";
  exit 1;
}

nodemon --watch "Submodules/My-Wallet-V3/src" -e "js" --exec "sh" ./scripts/build-js.sh
