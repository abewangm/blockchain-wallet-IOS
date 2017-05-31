set -ue
source .env

openssl s_client -connect blockchain.info:443 -showcerts < /dev/null | openssl x509 -outform DER > blockchain.der
openssl s_client -connect $STAGING:443 -showcerts < /dev/null | openssl x509 -outform DER > staging.der
openssl s_client -connect $DEV:443 -showcerts < /dev/null | openssl x509 -outform DER > dev.der
openssl s_client -connect $TESTNET:443 -showcerts < /dev/null | openssl x509 -outform DER > testnet.der
