# docker-nextcloudcli
An Alpine Linux Docker container for Nextcloud CLI syncronisation

Now on Docker Hub: https://hub.docker.com/r/boredazfcuk/nextcloudcli

## MANDATORY ENVIRONMENT VARIABLES

NC_USER: This is the user that you wish to log into Nextcloud as.

NC_PASSWORD: This is the password for the account named above.

NC_URL: This is the URL to the Nextcloud server's WebDAV URL

## DEFAULT ENVIRONMENT VARIABLES

USER: This is name of the user account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user on the host system for which you want to download files for. This user will be set as the owner of all downloaded files. If this variable is not set, it will default to 'user'

user_id: This is the User ID number of the above user account. This can be any number that isn't already in use. Ideally, you should set this to be the same ID number as the USER's ID on the host system. This will avoid permissions issues if syncing to your host's home directory. If this variable is not set, it will default to '1000'

GROUP: This is name of the group account that you wish to create within the container. This can be anything you choose, but ideally you would set this to match the name of the user's primary group on the host system. This This group will be set as the group for all downloaded files. If this variable is not set, it will default to 'group'

GID: This is the Group ID number of the above group. This can be any number that isn't already in use. Ideally, you should set this to be the same Group ID number as the user's primary group on the host system. If this variable is not set, it will default to '1000'

INTERVAL: This is the number of seconds between syncronisations. Common intervals would be: 3hrs - 10800, 4hrs - 14400, 6hrs - 21600 & 12hrs - 43200. If variable is not set it will default to every 6hrs.

```
docker create \
   --name <Contrainer Name> \
   --hostname <Hostname of container> \
   --network <Name of Docker network to connect to> \
   --restart=always \
   --env USER=<User Name> \
   --env user_id=<User ID> \
   --env GROUP=<Group Name> \
   --env GID=<Group ID> \
   --env INTERVAL=<Include this if you wish to override the default interval of 6hrs> \
   --env NC_USER="<Nextcloud login name>" \
   --env NC_PASSWORD="<Nexcloud password>" \
   --env NC_URL="Nexcloud WebDAV URL" \
   --volume <Bind mount to the destination folder on the host> \
   boredazfcuk/nextcloudcli
   ```
Here is the command I use to create a container on my host as an EXAMPLE:

```
docker create \
   --name NextcloudCLI-boredazfcuk \
   --hostname nextcloudcli_boredazfcuk \
   --network containers \
   --restart always \
   --env USER=boredazfcuk \
   --env user_id=1000 \
   --env GROUP=admins \
   --env GID=1010 \
   --env INTERVAL=43200 \
   --env NC_USER=boredazfcuk \
   --env NC_PASSWORD=notmyrealpassword \
   --env NC_URL=https://notreally.mynextcloudserver.com/remote.php/webdav/ \
   --env NC_CLIOPTIONS="--non-interactive --silent" \
   --env OWNCLOUD_BLACKLIST_TIME_MAX="1*60*60s" \
   --volume /home/boredazfcuk/Nextcloud:/home/boredazfcuk/Nextcloud \
   boredazfcuk/nextcloudcli
   ```

## VOLUME CONFIGURATION

This container will syncronise your Nextcloud account to the "/home/${USERNAME}/Nextcloud" directory inside the container. You need to create a bind mount on the host that is mapped into the container at this location.

To prevent everything being deleted by mistake, I have a failsafe built in. The launch script will look for a file called .mounted in the "/home/${USERNAME}/Nextcloud" folder. If this file is not present, it will not sync with the Nextcloud server. This is so that if the underlying disk/volume/whatever gets unmounted, sync will not occur. This prevents the script from filling up the root volume if the underlying volume isn't mounted for whatever reason. This file MUST be created manually and sync will not start without it.

Litecoin: LfmogjcqJXHnvqGLTYri5M8BofqqXQttk4