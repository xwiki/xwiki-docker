# ARG used in FROM must come first
ARG SOLR_VERSION=7.5.0

FROM busybox as buildenv

# ARG for build must come after the FROM statement
ARG XWIKI_VERSION=10.9
ARG XWIKI_URL_PREFIX="https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-data/${XWIKI_VERSION}"

WORKDIR /var/xwiki-solr-temp/

COPY ./solr-init.sh .
RUN wget "${XWIKI_URL_PREFIX}/xwiki-platform-search-solr-server-data-${XWIKI_VERSION}.jar"

FROM solr:${SOLR_VERSION}

COPY --from=buildenv /var/xwiki-solr-temp/ /docker-entrypoint-initdb.d/
