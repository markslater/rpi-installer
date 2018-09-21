#!/usr/bin/env bash
set -e

if [[ $# -ne 3 ]]
    then
        echo "Usage ${0} sdCard path-to-loxone-harmony-integration.jar path-to-ssh-public-key"
        echo "e.g. ${0} /dev/mmcblk0 ./loxone-harmony-integration-all.jar ~alice/.ssh/id_rsa.pub"
        exit 1
fi

DEVICE_NAME="${1}"
JAR_PATH="${2}"
PUBLIC_KEY="${3}"
CA_KEY="./ca.key"
CA_CERT="./ca.crt"
TA_KEY="./ta.key"

MYDIR="$(dirname "$(readlink -f "$0")")"

$MYDIR/generate-root-certificates.sh "${CA_KEY}" "${CA_CERT}" "${TA_KEY}"
$MYDIR/prepare-sd-card.sh "${DEVICE_NAME}" "${JAR_PATH}" "${PUBLIC_KEY}" "${CA_KEY}" "${CA_CERT}" "${TA_KEY}"
