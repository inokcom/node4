# inok in docker
FROM quay.io/inok/baseimage

RUN apt-get update \
    && apt-get install -y curl \
    && apt-get install -y python \
    && apt-get install -y --no-install-recommends git \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 5.7.1

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && npm install pm2 -g \
  && pm2 install pm2-server-monit \
  && pm2 install pm2-logrotate \
  && npm cache clear

# download dist
# 	&& pm2 install pm2-redis \

# broken node-gyp  && pm2 install pm2-webshell \
# https://github.com/pm2-hive/pm2-logrotate
# https://github.com/pm2-hive/pm2-webshell
# https://keymetrics.io/2015/06/10/pm2-ssh-expose-a-fully-capable-terminal-within-your-browser/

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
ADD package.json /tmp/package.json
RUN cd /tmp && npm install \
    && mkdir -p /opt/node && cp -a /tmp/node_modules /opt/node/  \
    && rm -r /tmp/* \
    && mkdir -p /opt/node/app

VOLUME ["/opt/node/app"]
WORKDIR /opt/node/

#CMD ["start"]
CMD ["./app/start"]

