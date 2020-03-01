#!/bin/ash

##### Functions #####
Initialise(){
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') | ***** Starting Nexcloud CLI syncronisation container *****"

   if [ -z "${user}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'user'"; user="user"; fi
   if [ -z "${user_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; user_id="1000"; fi
   if [ -z "${group}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; group="group"; fi
   if [ -z "${group_id}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; group_id="1000"; fi
   if [ -z "${nextcloud_syncronisation_interval}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Syncronisation nextcloud_syncronisation_interval not set, defaulting to 21600 seconds (6 hours) "; nextcloud_syncronisation_interval="21600"; fi
   if [ -z "${nextcloud_url}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud URL not set - exiting"; exit 1; fi
   if [ -z "${nextcloud_user}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud user name not set - exiting"; exit 1; fi
   if [ -z "${nextcloud_password}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud password not set - exiting"; exit 1; fi

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${user}:${user_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${group}:${group_id}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local directory: /home/${user}/Nextcloud"

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud user: ${nextcloud_user}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud password: ${nextcloud_password}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud URL: ${nextcloud_url}"
   if [ "${nextcloud_command_line_parameters}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud Command Line Options: ${nextcloud_command_line_parameters}"; fi


   if [ ! -d "/home/${user}/Nextcloud" ]; then
   echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Target folder does not exist, creating /home/${user}/Nextcloud"
      mkdir -p "/home/${user}/Nextcloud"
   fi

}

CreateGroup(){
   if [ -z "$(getent group "${group}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${group_id}" "${group}"
   elif [ ! "$(getent group "${group}" | cut -d: -f3)" = "${group_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group group_id mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${user}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -S -D -G "${group}" -u "${user_id}" "${user}" -h "/home/${user}"
   elif [ ! "$(getent passwd "${user}" | cut -d: -f3)" = "${user_id}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

CheckMount(){
   while [ ! -f "/home/${user}/Nextcloud/.mounted" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Local directory not mounted - retry in 5 minutes"
      sleep 300
   done
}

SetOwnerAndGroup(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of syncronised files, if required"
   find "/home/${user}/Nextcloud" ! -user "${user}" -exec chown "${user}" {} \;
   find "/home/${user}/Nextcloud" ! -group "${group}" -exec chgrp "${group}" {} \;
}

CheckNextcloudOnline(){
   while [ "$(nc -z nginx 443; echo $?)" -ne 0 ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud web server not contactable - retry in 2 minutes"
      sleep 120
   done
}

SyncNextcloud(){
   while :; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Syncronisation started for ${user}..."
      CheckMount
      CheckNextcloudOnline
      /bin/su -s /bin/ash "${user}" -c '/usr/bin/nextcloudcmd --user '"${nextcloud_user}"' --password '"${nextcloud_password}"' ${nextcloud_command_line_parameters} '"/home/${user}/Nextcloud"' '"${nextcloud_url}"'; echo $? >/tmp/exit_code'
      SetOwnerAndGroup
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Syncronisation for ${user} complete"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Next syncronisation at $(date +%H:%M -d "${nextcloud_syncronisation_interval} seconds")"
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