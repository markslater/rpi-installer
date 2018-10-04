#!/usr/bin/env bash
set -e

if [[ $# -ne 5 ]]
    then
        echo "Usage ${0} ca.key ca.crt ta.key public-ip unique-client-name"
        echo "e.g. ${0} ca.key ca.crt ta.key 208.67.222.222 alice"
        exit 1
fi


CA_KEY="${1}"
CA_CERT="${2}"
TA_KEY="${3}"
PUBLIC_IP_ADDRESS="${4}"
CLIENT_CN="${5}"

cat > "./${CLIENT_CN}.ovpn" <<- EOM
client
dev tun
proto udp
remote ${PUBLIC_IP_ADDRESS} 1194
resolv-retry infinite
nobind

# do we need this on Android?
;user nobody
;group nobody

persist-key
persist-tun

# Wireless networks often produce a lot
# of duplicate packets.  Set this flag
# to silence duplicate packet warnings.
;mute-replay-warnings

remote-cert-tls server

key-direction 1
cipher AES-256-CBC
auth SHA512
verb 3
mute 20

<ca>
$(cat "${CA_CERT}")
</ca>
<key>
EOM

CLIENT_CERTIFICATE=`openssl req -nodes -new -keyout >(cat >> "./${CLIENT_CN}.ovpn") -subj "/C=GB/ST=London/L=London/O=Private/CN=${CLIENT_CN}" | openssl x509 -req -days 3650 -CA "${CA_CERT}" -CAkey "${CA_KEY}" -CAcreateserial -extfile <(cat <<- EOM
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
extendedKeyUsage = clientAuth
keyUsage = digitalSignature
EOM
)`

cat >> "./${CLIENT_CN}.ovpn" <<- EOM
</key>
<cert>
${CLIENT_CERTIFICATE}
</cert>
<tls-auth>
$(cat "${TA_KEY}")
</tls-auth>
EOM