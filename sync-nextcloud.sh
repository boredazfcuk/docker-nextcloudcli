#!/bin/ash

##### Functions #####
Initialise(){
   echo
   nextcloud_domain="$(echo "${nextcloud_url}" | awk -F/ '{print $3}')"
   nextcloud_login_url="${nextcloud_url/\/remote.php\/webdav/}login"
   echo "$(date '+%c') INFO:    ***** Starting Nexcloud CLI synchronisation container *****"
   echo "$(date '+%c') INFO:    $(cat /etc/*-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g')"
   echo "$(date '+%c') INFO:    Local user: ${user:=user}:${user_id:=1000}"
   echo "$(date '+%c') INFO:    Local group: ${group:=group}:${group_id:=1000}"
   echo "$(date '+%c') INFO:    Local directory: /home/${user}/Nextcloud"
   if [ -z "${nextcloud_user}" ]; then echo "$(date '+%c') ERROR:   Nextcloud user name not set - exiting"; exit 1; fi
   if [ -z "${nextcloud_password}" ]; then echo "$(date '+%c') ERROR:   Nextcloud password not set - exiting"; exit 1; fi
   if [ -z "${nextcloud_url}" ]; then echo "$(date '+%c') ERROR:   Nextcloud URL not set - exiting"; exit 1; fi
   echo "$(date '+%c') INFO:    Nextcloud domain: ${nextcloud_domain}"
   echo "$(date '+%c') INFO:    Nextcloud user: ${nextcloud_user}"
   echo "$(date '+%c') INFO:    Nextcloud password: ${nextcloud_password}"
   echo "$(date '+%c') INFO:    Nextcloud URL: ${nextcloud_url}"
   echo "$(date '+%c') INFO:    Nextcloud login page URL: ${nextcloud_login_url}"
   echo "$(date '+%c') INFO:    Nextcloud synchronisation interval: ${nextcloud_synchronisation_interval:=21600}"
   echo "$(date '+%c') INFO:    Nextcloud excluded files: ${nextcloud_excluded_files:=None}"
   if [ "${nextcloud_command_line_options}" ]; then echo "$(date '+%c') INFO:    Nextcloud Command Line Options: ${nextcloud_command_line_options}"; fi
   if [ ! -d "/home/${user}/Nextcloud" ]; then
   echo "$(date '+%c') WARNING: Target folder does not exist, creating /home/${user}/Nextcloud"
      mkdir -p "/home/${user}/Nextcloud"
   fi
}

CreateGroup(){
   if [ "$(grep -c "^${group}:x:${group_id}:" "/etc/group")" -eq 1 ]; then
      echo "$(date '+%c') INFO     Group, ${group}:${group_id}, already created"
   else
      if [ "$(grep -c "^${group}:" "/etc/group")" -eq 1 ]; then
         echo "$(date '+%c') ERROR    Group name, ${group}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${group_id}:" "/etc/group")" -eq 1 ]; then
         if [ "${force_gid}" = "True" ]; then
            group="$(grep ":x:${group_id}:" /etc/group | awk -F: '{print $1}')"
            echo "$(date '+%c') WARNING  Group id, ${group_id}, already exists - continuing as force_gid variable has been set. Group name to use: ${group}"
         else
            echo "$(date '+%c') ERROR    Group id, ${group_id}, already in use - exiting"
            sleep 120
            exit 1
         fi
      else
         echo "$(date '+%c') INFO     Creating group ${group}:${group_id}"
         addgroup -g "${group_id}" "${group}"
      fi
   fi
}

CreateUser(){
   if [ "$(grep -c "^${user}:x:${user_id}:${group_id}" "/etc/passwd")" -eq 1 ]; then
      echo "$(date '+%c') INFO     User, ${user}:${user_id}, already created"
   else
      if [ "$(grep -c "^${user}:" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%c') ERROR    User name, ${user}, already in use - exiting"
         sleep 120
         exit 1
      elif [ "$(grep -c ":x:${user_id}:$" "/etc/passwd")" -eq 1 ]; then
         echo "$(date '+%c') ERROR    User id, ${user_id}, already in use - exiting"
         sleep 120
         exit 1
      else
         echo "$(date '+%c') INFO     Creating user ${user}:${user_id}"
         adduser -s /bin/ash -D -G "${group}" -u "${user_id}" "${user}" -h "/home/${user}"
      fi
   fi
}

CheckMount(){
   while [ ! -f "/home/${user}/Nextcloud/.mounted" ]; do
      echo "$(date '+%c') ERROR:   Local directory not mounted. /home/${user}/Nextcloud/.mounted does not exist - retry in 5 minutes"
      sleep 300
   done
}

SetOwnerAndGroup(){
   echo "$(date '+%c') INFO:    Correct owner and group of syncronised files, if required"
   find "/home/${user}/Nextcloud" ! -user "${user}" -exec chown "${user}" {} \;
   find "/home/${user}/Nextcloud" ! -group "${group}" -exec chgrp "${group}" {} \;
}

CheckNextcloudOnline(){
   echo "$(date '+%c') INFO:    Check Nextcloud server is online"
   while ! wget --quiet --spider "${nextcloud_login_url}" >/dev/null 2>&1; do
      echo "$(date '+%c') ERROR:   Nextcloud web server not contactable - retry in 5 seconds"
      sleep 5
   done
   echo "$(date '+%c') INFO:    Nextcloud server is available"
}

SyncNextcloud(){
   while :; do
      echo "$(date '+%c') INFO:    Synchronisation started for ${user}..."
      CheckMount
      CheckNextcloudOnline
      /bin/su -s /bin/ash "${user}" -c '/usr/bin/nextcloudcmd --non-interactive --user '"${nextcloud_user}"' --password '"${nextcloud_password}"' ${nextcloud_command_line_options} '"/home/${user}/Nextcloud"' '"${nextcloud_url}"'; echo $? >/tmp/exit_code'
      SetOwnerAndGroup
      echo "$(date '+%c') INFO:    Synchronisation for ${user} complete"
      echo "$(date '+%c') INFO:    Next synchronisation at $(date +%H:%M -d "${nextcloud_synchronisation_interval} seconds")"
      sleep "${nextcloud_synchronisation_interval}"
   done
}

##### Script #####
Initialise
CreateGroup
CreateUser
CheckMount
SetOwnerAndGroup
SyncNextcloud