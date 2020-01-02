#!/bin/ash

##### Functions #####
Initialise(){
   echo -e "\n"
   echo "$(date '+%Y-%m-%d %H:%M:%S') | ***** Starting Nexcloud CLI syncronisation container *****"

   if [ -z "${USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User name not set, defaulting to 'user'"; USER="user"; fi
   if [ -z "${UID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: User ID not set, defaulting to '1000'"; UID="1000"; fi
   if [ -z "${GROUP}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group name not set, defaulting to 'group'"; GROUP="group"; fi
   if [ -z "${GID}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Group ID not set, defaulting to '1000'"; GID="1000"; fi
   if [ -z "${NC_INTERVAL}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Syncronisation NC_INTERVAL not set, defaulting to 21600 seconds (6 hours) "; NC_INTERVAL="21600"; fi
   if [ -z "${NC_URL}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud URL not set - exiting"; exit 1; fi
   if [ -z "${NC_USER}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud user name not set - exiting"; exit 1; fi
   if [ -z "${NC_PASSWORD}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Nextcloud password not set - exiting"; exit 1; fi

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local user: ${USER}:${UID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local group: ${GROUP}:${GID}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Local directory: /home/${USER}/Nextcloud"

   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud user: ${NC_USER}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud password: ${NC_PASSWORD}"
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud URL: ${NC_URL}"
   if [ ! -z "${NC_CLIOPTIONS}" ]; then echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Nextcloud Command Line Options: ${NC_CLIOPTIONS}"; fi


   if [ ! -d "/home/${USER}/Nextcloud" ]; then
   echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: Target folder does not exist, creating /home/${USER}/Nextcloud"
      mkdir -p "/home/${USER}/Nextcloud"
   fi

}

CreateGroup(){
   if [ -z "$(getent group "${GROUP}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Group ID available, creating group"
      addgroup -g "${GID}" "${GROUP}"
   elif [ ! "$(getent group "${GROUP}" | cut -d: -f3)" = "${GID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Group GID mismatch - exiting"
      exit 1
   fi
}

CreateUser(){
   if [ -z "$(getent passwd "${USER}" | cut -d: -f3)" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    User ID available, creating user"
      adduser -S -D -G "${GROUP}" -u "${UID}" "${USER}" -h "/home/${USER}"
   elif [ ! "$(getent passwd "${USER}" | cut -d: -f3)" = "${UID}" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   User ID already in use - exiting"
      exit 1
   fi
}

CheckMount(){
   while [ ! -f "/home/${USER}/Nextcloud/.mounted" ]; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR:   Local directory not mounted - retry in 5 minutes"
      sleep 300
   done
}

SetOwnerAndGroup(){
   echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Correct owner and group of syncronised files, if required"
   find "/home/${USER}/Nextcloud" ! -user "${USER}" -exec chown "${USER}" {} \;
   find "/home/${USER}/Nextcloud" ! -group "${GROUP}" -exec chgrp "${GROUP}" {} \;
}

SyncNextcloud(){
   while :; do
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Syncronisation started for ${USER}..."
      CheckMount
      /bin/su -s /bin/ash "${USER}" -c '/usr/bin/nextcloudcmd --user '"${NC_USER}"' --password '"${NC_PASSWORD}"' ${NC_CLIOPTIONS} '"/home/${USER}/Nextcloud"' '"${NC_URL}"'; echo $? >/tmp/EXIT_CODE'
      SetOwnerAndGroup
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Syncronisation for ${USER} complete"
      echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Next syncronisation at $(date +%H:%M -d "${NC_INTERVAL} seconds")"
      sleep "${NC_INTERVAL}"
   done
}

##### Script #####
Initialise
CreateGroup
CreateUser
CheckMount
SetOwnerAndGroup
SyncNextcloud