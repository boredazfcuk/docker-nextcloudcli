#!/bin/ash
EXIT_CODE=0
EXIT_CODE="$(cat /tmp/EXIT_CODE)"
if [ "${EXIT_CODE}" -ne 0 ]; then
   echo "Nextcloud CLI sync error: ${EXIT_CODE}"
   exit 1
fi
echo "Nextcloud CLI sync successful"
exit 0