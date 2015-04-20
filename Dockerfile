# inok in docker
FROM quay.io/inok/baseimage

RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y python \
    && apt-get install -y --no-install-recommends git \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

# verify gpg and sha256: http://nodejs.org/dist/v0.10.31/SHASUMS256.txt.asc
# gpg: aka "Timothy J Fontaine (Work) <tj.fontaine@joyent.com>"
RUN gpg --keyserver pgp.mit.edu --recv-keys 7937DFD2AB06298B2293C3187D33FF9D0246406D

# https://registry.hub.docker.com/_/node/
ENV NODE_VERSION 0.10.38
RUN curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz" \
	&& curl -SLO "http://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
	&& gpg --verify SHASUMS256.txt.asc \
	&& grep " node-v$NODE_VERSION-linux-x64.tar.gz\$" SHASUMS256.txt.asc | sha256sum -c - \
	&& tar -xzf "node-v$NODE_VERSION-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
	&& rm "node-v$NODE_VERSION-linux-x64.tar.gz" SHASUMS256.txt.asc

RUN npm install pm2 -g

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
ADD package.json /tmp/package.json
RUN cd /tmp && npm install \
    && mkdir -p /opt/node && cp -a /tmp/node_modules /opt/node/  \
    && rm -r /tmp/* \
    && mkdir -p /opt/node/app

VOLUME ["/opt/node/app"]
WORKDIR /opt/node/

EXPOSE  4000
CMD [ "pm2","--no-daemon","start","/opt/node/app/processes.json" ]
