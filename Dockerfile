FROM --platform=linux/amd64 melle2/wine-steamcmd-ubuntu:24.04-3

LABEL org.opencontainers.image.title="SCUM Server Automation on Wine"
ARG SSA_VERSION=6.2.0
ARG SSA_SHA256=99517154c337b669890a8ea84167dca86fcd7f56dab6c345ab8d16b07feac5c7
USER root
ENV DEBIAN_FRONTEND=noninteractive HOME=/data/home WINEPREFIX=/data/wine \
    WINEARCH=win64 WINEDEBUG=-all WINEDLLOVERRIDES="dwmapi=n,b;mscoree=d" TZ=Asia/Ho_Chi_Minh
RUN apt-get update && apt-get install -y --no-install-recommends curl unzip gosu tini procps ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/scumsa /data \
    && curl -fL --retry 3 "https://scumsa.com/releases/SCUM-Server-Automation-v${SSA_VERSION}.zip" -o /tmp/scumsa.zip \
    && printf '%s  %s\n' "$SSA_SHA256" /tmp/scumsa.zip | sha256sum -c - \
    && unzip -q /tmp/scumsa.zip -d /opt/scumsa && rm /tmp/scumsa.zip
COPY --chmod=0755 scripts/init.sh /opt/scum-init.sh
WORKDIR /data/manager
STOPSIGNAL SIGINT
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/opt/scum-init.sh"]