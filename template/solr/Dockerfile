# ARG used in FROM must come first
ARG SOLR_VERSION=$solrVersion

FROM busybox as buildenv

# ARG for build must come after the FROM statement
ARG XWIKI_VERSION=$xwikiVersion
ARG XWIKI_URL_PREFIX="https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-data/\${XWIKI_VERSION}"

ENV XWIKI_SOLR_SHA256 $xwikisolrSha256

WORKDIR /var/xwiki-solr-temp/

COPY ./solr-init.sh .
RUN wget "\${XWIKI_URL_PREFIX}/xwiki-platform-search-solr-server-data-\${XWIKI_VERSION}.jar"
RUN echo "\$XWIKI_SOLR_SHA256  xwiki-platform-search-solr-server-data-\${XWIKI_VERSION}.jar" | sha256sum -c - 

FROM solr:\${SOLR_VERSION}

COPY --from=buildenv /var/xwiki-solr-temp/ /docker-entrypoint-initdb.d/