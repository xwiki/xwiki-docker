# ---------------------------------------------------------------------------
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
# ---------------------------------------------------------------------------

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

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \\ \\  / /    \\ \\  /\\  / /  __   | | / ]  __
#      > `' <      \\ \\/  \\/ /  [  |  | '' <  [  |
#    _/ /'`\\ \\_     \\  /\\  /    | |  | |`\\ \\  | |
#   |____||____|     \\/  \\/    [___][__|  \\_][___]

LABEL org.opencontainers.image.authors='XWiki Development Team <committers@xwiki.org>'
LABEL org.opencontainers.image.url='https://hub.docker.com/_/xwiki'
LABEL org.opencontainers.image.documentation='https://hub.docker.com/_/xwiki'
LABEL org.opencontainers.image.source='https://github.com/xwiki/xwiki-docker.git'
LABEL org.opencontainers.image.vendor='xwiki.org'
LABEL org.opencontainers.image.licenses='LGPL-2.1'

# Copy Solr cores configuration to their respective locations
COPY --from=builder --chown=8983 /home /opt/solr/server/solr/

# Precreate Solr cores and start Solr server
ENTRYPOINT ["bash"]
CMD ["-c", "precreate-core xwiki; precreate-core xwiki_events; precreate-core xwiki_extension_index; precreate-core xwiki_ratings; exec solr -f"]
