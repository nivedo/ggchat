#!/bin/bash

openssl x509 -in aps_development.cer -inform der -out ggchatCert.pem
openssl pkcs12 -nocerts -out ggchatKey.pem -in ggchatKey.p12
cat ggchatCert.pem ggchatKey.pem > ck.pem

