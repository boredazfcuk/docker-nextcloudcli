FROM alpine:latest
MAINTAINER boredazfcuk

COPY sync-nextcloud.sh /usr/local/bin/sync-nextcloud.sh

RUN echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Install Nextcloud Client" && \
   apk add --no-cache nextcloud-client coreutils && \
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Set permissions on startup script" && \
   chmod +x /usr/local/bin/sync-nextcloud.sh && \
echo "$(date '+%Y-%m-%d %H:%M:%S') INFO:    Amend Nextloud ignore list" && \
   echo ".mounted" >>/etc/Nextcloud/sync-exclude.lst

HEALTHCHECK --start-period=10s --interval=1m --timeout=10s \
   CMD (if [ "$(cat /tmp/EXIT_CODE)" = 0 ]; then exit 0; else exit 1; fi)  

CMD /usr/local/bin/sync-nextcloud.sh