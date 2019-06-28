# ARG used in FROM must come first
ARG SOLR_VERSION=7.5.0

FROM busybox as buildenv

# ARG for build must come after the FROM statement
ARG XWIKI_VERSION=11.5
ARG XWIKI_URL_PREFIX="https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-data/${XWIKI_VERSION}"

ENV XWIKI_SOLR_SHA256 216c46c11c41a1195cd23f2f568a70acdcdd731f1e179d7f1d4e93c40cacbcb1

WORKDIR /var/xwiki-solr-temp/

COPY ./solr-init.sh .
RUN wget "${XWIKI_URL_PREFIX}/xwiki-platform-search-solr-server-data-${XWIKI_VERSION}.jar"
RUN echo "$XWIKI_SOLR_SHA256  xwiki-platform-search-solr-server-data-${XWIKI_VERSION}.jar" | sha256sum -c - 

FROM solr:${SOLR_VERSION}

COPY --from=buildenv /var/xwiki-solr-temp/ /docker-entrypoint-initdb.d/