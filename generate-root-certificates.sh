#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]
    then
        echo "Usage ${0} ca.key ca.crt ta.key"
        exit 1
fi

CA_KEY="${1}"
CA_CERT="${2}"
TA_KEY="${3}"

openssl req -days 3650 -nodes -new -x509 -keyout "${CA_KEY}" -out "${CA_CERT}" -subj "/C=GB/ST=London/L=London/O=Private/CN=root.ca"
chmod 600 ${CA_KEY}
openvpn --genkey --secret "${TA_KEY}"