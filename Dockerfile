####################################################
# GOLANG BUILDER
####################################################
FROM golang:1.11 as go_builder

COPY . /go/src/github.com/malice-plugins/zoner
WORKDIR /go/src/github.com/malice-plugins/zoner
RUN go get -u github.com/golang/dep/cmd/dep && dep ensure
RUN go build -ldflags "-s -w -X main.Version=v$(cat VERSION) -X main.BuildTime=$(date -u +%Y%m%d)" -o /bin/avscan

####################################################
# PLUGIN BUILDER
####################################################
FROM ubuntu:bionic

LABEL maintainer "https://github.com/blacktop"

LABEL malice.plugin.repository = "https://github.com/malice-plugins/zoner.git"
LABEL malice.plugin.category="av"
LABEL malice.plugin.mime="*"
LABEL malice.plugin.docker.engine="*"

# Create a malice user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN groupadd -r malice \
  && useradd --no-log-init -r -g malice malice \
  && mkdir /malware \
  && chown -R malice:malice /malware

ARG ZONE_KEY
ENV ZONE_KEY=$ZONE_KEY

ENV ZONE 1.3.0

RUN buildDeps='ca-certificates wget build-essential' \
  && apt-get update -qq \
  && apt-get install -yq $buildDeps libc6-i386 \
  && echo "===> Install Zoner AV..." \
  && wget -q -P /tmp http://update.zonerantivirus.com/download/zav-${ZONE}-ubuntu-amd64.deb \
  && dpkg -i /tmp/zav-${ZONE}-ubuntu-amd64.deb; \
  if [ "x$ZONE_KEY" != "x" ]; then \
  echo "===> Updating License Key..."; \
  sed -i "s/UPDATE_KEY.*/UPDATE_KEY = ${ZONE_KEY}/g" /etc/zav/zavd.conf; \
  fi \
  && echo "===> Clean up unnecessary files..." \
  && apt-get purge -y --auto-remove $buildDeps && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Ensure ca-certificates is installed for elasticsearch to use https
RUN apt-get update -qq && apt-get install -yq --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt/malice
RUN if [ "x$ZONE_KEY" != "x" ]; then \
  echo "===> Update zoner definitions..."; \
  /etc/init.d/zavd update; \
  fi

# Add EICAR Test Virus File to malware folder
ADD http://www.eicar.org/download/eicar.com.txt /malware/EICAR

COPY --from=go_builder /bin/avscan /bin/avscan

WORKDIR /malware

ENTRYPOINT ["/bin/avscan"]
CMD ["--help"]

####################################################
# CMD /etc/init.d/zavd start --no-daemon && zavcli --no-show=clean,nonstandard --color /malware
