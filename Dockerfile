FROM alpine:3.14
MAINTAINER boredazfcuk

RUN echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD STARTED FOR NEXTCLOUDCLI *****" && \
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Install Nextcloud Client" && \
   apk add --no-cache nextcloud-client coreutils tzdata && \
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Amend Nextloud ignore list" && \
   echo ".mounted" >>/etc/Nextcloud/sync-exclude.lst && \
   echo ".nextcloud_sync" >>/etc/Nextcloud/sync-exclude.lst && \
   echo "]desktop.ini" >>/etc/Nextcloud/sync-exclude.lst && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

COPY --chmod=0755 sync-nextcloud.sh /usr/local/bin/sync-nextcloud.sh
COPY --chmod=0755 healthcheck.sh /usr/local/bin/healthcheck.sh

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s CMD /usr/local/bin/healthcheck.sh

CMD /usr/local/bin/sync-nextcloud.sh
