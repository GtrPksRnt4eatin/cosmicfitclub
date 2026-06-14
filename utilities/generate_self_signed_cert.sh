#! /bin/sh

mkdir certs
openssl genrsa -des3 -passout pass:x -out certs/server.pass.key 2048
openssl rsa -passin pass:x -in certs/server.pass.key -out certs/server.key
rm certs/server.pass.key
openssl req -new -key certs/server.key -out certs/server.csr
openssl x509 -req -sha256 -days 365 -in certs/server.csr -signkey certs/server.key -out certs/server.crt