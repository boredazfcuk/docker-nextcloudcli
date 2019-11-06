#!/bin/ash
EXIT_CODE="$(cat /tmp/EXIT_CODE)"
if [ "${EXIT_CODE}" -ne 0 ]; then
   echo "Exit code: ${EXIT_CODE}"
   exit 1
fi
exit 0