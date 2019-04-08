FROM node:slim

LABEL "com.github.actions.name"="check master"
LABEL "com.github.actions.description"="Checks if current master has changes in paths changed in a PR"
LABEL "com.github.actions.icon"="git-pull-request"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="http://github.com/codesuki/check-master-action"
LABEL "homepage"="http://github.com/codesuki/check-master-action"
LABEL "maintainer"="Neri Marschik <codesuki@users.noreply.github.com>"

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm ci
ADD entrypoint.js /entrypoint.js
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["node", "/entrypoint.js"]

WORKDIR /
