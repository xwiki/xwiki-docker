# Use the curl image to download required Solr cores
FROM curlimages/curl:8.2.0 AS downloader
ARG XWIKI_VERSION=15.5
WORKDIR /home/curl_user
ENV SOLR_SERVER_CORE_URL=https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-core/${XWIKI_VERSION}/xwiki-platform-search-solr-server-core-${XWIKI_VERSION}.jar
ENV SOLR_CORE_MINIMAL_URL=https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-core-minimal/${XWIKI_VERSION}/xwiki-platform-search-solr-server-core-minimal-${XWIKI_VERSION}.zip

# Downloading the Solr cores
RUN echo $SOLR_SERVER_CORE_URL && \
    curl $SOLR_SERVER_CORE_URL -o ./xwiki-server-core.zip && \
    curl $SOLR_CORE_MINIMAL_URL -o ./xwiki-minimal-core.zip

# Unzipping the downloaded Solr cores
FROM dockerqa/unzip:latest AS builder
COPY --from=downloader /home/curl_user/*.zip /unzip/
RUN unzip -qq /unzip/xwiki-server-core.zip -d /home/xwiki && \
    unzip -qq /unzip/xwiki-minimal-core.zip -d /home/xwiki_events && \
    unzip -qq /unzip/xwiki-minimal-core.zip -d /home/xwiki_extension_index && \
    unzip -qq /unzip/xwiki-minimal-core.zip -d /home/xwiki_ratings

# Final image using the official Solr 8 image as the base
FROM solr:8
# Copy Solr cores configuration to their respective locations
COPY --from=builder --chown=8983 /home /opt/solr/server/solr/

# Precreate Solr cores and start Solr server
ENTRYPOINT ["bash"]
CMD ["-c", "precreate-core xwiki; precreate-core xwiki_events; precreate-core xwiki_extension_index; precreate-core xwiki_ratings; exec solr -f"]
