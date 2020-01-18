#!/bin/ash
exit_code=0
exit_code="$(cat /tmp/exit_code)"
if [ "${exit_code}" -ne 0 ]; then
   echo "Nextcloud CLI sync error: ${exit_code}"
   exit 1
fi
echo "Nextcloud CLI sync successful"
exit 0