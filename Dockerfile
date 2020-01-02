FROM alpine:latest
MAINTAINER boredazfcuk

RUN echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Install Nextcloud Client" && \
   apk add --no-cache nextcloud-client coreutils tzdata && \
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Amend Nextloud ignore list" && \
   echo ".mounted" >>/etc/Nextcloud/sync-exclude.lst

COPY sync-nextcloud.sh /usr/local/bin/sync-nextcloud.sh
COPY healthcheck.sh /usr/local/bin/healthcheck.sh

RUN echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set permissions on scripts" && \
   chmod +x /usr/local/bin/sync-nextcloud.sh /usr/local/bin/healthcheck.sh && \
echo "$(date '+%d/%m/%Y - %H:%M:%S') | ***** BUILD COMPLETE *****"

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD /usr/local/bin/healthcheck.sh

CMD /usr/local/bin/sync-nextcloud.sh