#!/usr/bin/env bash

set -euo pipefail

DEVICE="rosemary"

META="$(mktemp)" # Will be filled META-INF/com/android/metadata

getMetadataProp()
{
    PROPNAME="${1}"
    awk -F "=" "{ if (\$1 == \"${PROPNAME}\") print \$2 }" "${META}"
}

OTA="${1}"

if [[ ! -f "${1}" ]]
then
    echo "Zip not found, bruh!"
fi

echo "- Generating LineageOS OTA for ${1}"

echo "-- Writing metatada in ${META}"

unzip -p "${OTA}" "META-INF/com/android/metadata" > "${META}"

SDK="$(getMetadataProp "post-sdk-level")"
INCR="$(getMetadataProp "post-build-incremental")"
TS="$(getMetadataProp "post-timestamp")"
BUILD_DATE="$(date --date="@${TS}" +%Y%m%d)"

echo "-- SDK: ${SDK}"
echo "-- Incremental: ${INCR}"
echo "-- Build timestamp: ${TS} (date ${BUILD_DATE})"

LINEAGE_VER=""

case "${SDK}" in
    30)
        LINEAGE_VER="18.1"
        ;;
    32)
        LINEAGE_VER="19.1"
        ;;
    *)
        echo "Unknown sdk ver"
        exit 1
esac

VER_DIRNAME="lineage-${LINEAGE_VER/\./}"
VER_FILENAME="lineage-${LINEAGE_VER}-${BUILD_DATE}-UNOFFICIAL-rosemary.zip"

echo "-- Lineage ver: ${LINEAGE_VER} (${VER_DIRNAME})"
echo "-- Finished reading props"

echo "-- Writing ota json"

cat << EOF > "${VER_DIRNAME}/${DEVICE}.json"
{
    "response": [
        {
            "datetime": ${TS},
            "filename": "${VER_FILENAME}",
            "id": "$(md5sum "${OTA}" | awk '{print $1}')",
            "romtype": "unofficial",
            "size": "$(stat -c%s "${OTA}")",
            "url": "https://github.com/RedmiNote10S/lineage_releases/releases/download/${TS}/${VER_FILENAME}",
            "version": "${LINEAGE_VER}"
        }
    ]
}
EOF

echo "-- Generated ${VER_DIRNAME}/${DEVICE}.json"

echo "-- Making sure json seems valid"
jq -r . "${VER_DIRNAME}/${DEVICE}.json"
echo "-- Valid JSON"

