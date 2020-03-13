#!/bin/ash

##### Functions #####
Initialise(){
   echo -e "\n"
   echo "$(date '+%c') | ***** Starting Nexcloud CLI syncronisation container *****"
   echo "$(date '+%c') | $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   echo "$(date '+%c') INFO:    Local user: ${user:=user}:${user_id:=1000}"
   echo "$(date '+%c') INFO:    Local group: ${group:=group}:${group_id:=1000}"
   echo "$(date '+%c') INFO:    Local directory: /home/${user}/Nextcloud"
   if [ -z "${nextcloud_user}" ]; then echo "$(date '+%c') ERROR:   Nextcloud user name not set - exiting"; exit 1; fi
   if [ -z "${nextcloud_password}" ]; then echo "$(date '+%c') ERROR:   Nextcloud password not set - exiting"; exit 1; fi
   if [ -z "${nextcloud_url}" ]; then echo "$(date '+%c') ERROR:   Nextcloud URL not set - exiting"; exit 1; fi
   echo "$(date '+%c') INFO:    Nextcloud user: ${nextcloud_user}"
   echo "$(date '+%c') INFO:    Nextcloud password: ${nextcloud_password}"
   echo "$(date '+%c') INFO:    Nextcloud URL: ${nextcloud_url}"
   echo "$(date '+%c') INFO:    Nextcloud synchronisation interval: ${nextcloud_syncronisation_interval:=21600}"
   if [ "${nextcloud_command_line_parameters}" ]; then echo "$(date '+%c') INFO:    Nextcloud Command Line Options: ${nextcloud_command_line_parameters}"; fi
   if [ ! -d "/home/${user}/Nextcloud" ]; then
   echo "$(date '+%c') WARNING: Target folder does not exist, creating /home/${user}/Nextcloud"
      mkdir -p "/home/${user}/Nextcloud"
   fi
}

CreateGroup(){
   if [ -z "$(getent group "${group}" | cut -d: -f3)" ]; then
      echo "$(date '+%c') INFO:    Group ID available, creating group"
      addgroup -g "${group_id}" "${group}"
   elif [ ! "$(getent group "${group}" | cut -d: -f3)" = "${group_id}" ]; then
      echo "$(date '+%c') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${user}" | cut -d: -f3)" ]; then
      echo "$(date '+%c') INFO:    User ID available, creating user"
      adduser -S -D -G "${group}" -u "${user_id}" "${user}" -h "/home/${user}"
   elif [ ! "$(getent passwd "${user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%c') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

CheckMount(){
   while [ ! -f "/home/${user}/Nextcloud/.mounted" ]; do
      echo "$(date '+%c') ERROR:   Local directory not mounted - retry in 5 minutes"
      sleep 300
   done
}

SetOwnerAndGroup(){
   echo "$(date '+%c') INFO:    Correct owner and group of syncronised files, if required"
   find "/home/${user}/Nextcloud" ! -user "${user}" -exec chown "${user}" {} \;
   find "/home/${user}/Nextcloud" ! -group "${group}" -exec chgrp "${group}" {} \;
}

CheckNextcloudOnline(){
   while [ "$(nc -z nginx 443; echo $?)" -ne 0 ]; do
      echo "$(date '+%c') ERROR:   Nextcloud web server not contactable - retry in 2 minutes"
      sleep 120
   done
}

SyncNextcloud(){
   while :; do
      echo "$(date '+%c') INFO:    Syncronisation started for ${user}..."
      CheckMount
      CheckNextcloudOnline
      /bin/su -s /bin/ash "${user}" -c '/usr/bin/nextcloudcmd --user '"${nextcloud_user}"' --password '"${nextcloud_password}"' ${nextcloud_command_line_parameters} '"/home/${user}/Nextcloud"' '"${nextcloud_url}"'; echo $? >/tmp/exit_code'
      SetOwnerAndGroup
      echo "$(date '+%c') INFO:    Syncronisation for ${user} complete"
      echo "$(date '+%c') INFO:    Next syncronisation at $(date +%H:%M -d "${nextcloud_syncronisation_interval} seconds")"
      sleep "${nextcloud_syncronisation_interval}"
   done
}

##### Script #####
Initialise
CreateGroup
CreateUser
CheckMount
SetOwnerAndGroup
SyncNextcloud