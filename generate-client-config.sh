#!/usr/bin/env bash

if [[ $# -ne 2 ]]
    then
        echo "Usage ${0} unique-client-name public-ip"
        echo "e.g. ${0} alice 208.67.222.222"
        exit 1
fi

CLIENT_CN="${1}"
PUBLIC_IP_ADDRESS="${2}"

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

# Verify server certificate by checking that the
# certicate has the correct key usage set.
# This is an important precaution to protect against
# a potential attack discussed here:
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the keyUsage set to
#   digitalSignature, keyEncipherment
# and the extendedKeyUsage to
#   serverAuth
# EasyRSA can do this for you.
# remote-cert-tls server

key-direction 1
cipher AES-256-CBC
verb 3
mute 20

<ca>
$(cat ./ca.crt)
</ca>
<key>
EOM

CLIENT_CERTIFICATE=`openssl req -nodes -new -keyout >(cat >> "./${CLIENT_CN}.ovpn") -subj "/C=GB/ST=London/L=London/O=Private/CN=client" | openssl x509 -req -days 3650 -CA ./ca.crt -CAkey ./ca.key -CAcreateserial`

cat >> "./${CLIENT_CN}.ovpn" <<- EOM
</key>
<cert>
${CLIENT_CERTIFICATE}
</cert>
<tls-auth>
$(cat ./ta.key)
</tls-auth>
EOM