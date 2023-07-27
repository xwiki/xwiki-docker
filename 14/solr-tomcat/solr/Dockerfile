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
WORKDIR /home/curl_user
ENV solrCoreUrl="https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-core/14.10.14/xwiki-platform-search-solr-server-core-14.10.14.jar"
ENV solrMinimalCoreUrl="https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-core-minimal/14.10.14/xwiki-platform-search-solr-server-core-minimal-14.10.14.zip"

# Downloading the Solr cores
RUN curl https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-core/14.10.14/xwiki-platform-search-solr-server-core-14.10.14.jar -o ./xwiki-server-core.zip &&     curl https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-core-minimal/14.10.14/xwiki-platform-search-solr-server-core-minimal-14.10.14.zip -o ./xwiki-minimal-core.zip

# Unzipping the downloaded Solr cores
FROM dockerqa/unzip:latest AS builder
COPY --from=downloader /home/curl_user/*.zip /unzip/
RUN unzip -qq /unzip/xwiki-server-core.zip -d /home/xwiki &&     unzip -qq /unzip/xwiki-minimal-core.zip -d /home/xwiki_events &&     unzip -qq /unzip/xwiki-minimal-core.zip -d /home/xwiki_extension_index &&     unzip -qq /unzip/xwiki-minimal-core.zip -d /home/xwiki_ratings

# Final image using the official Solr 8 image as the base
FROM solr:8

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \ \  / /    \ \  /\  / /  __   | | / ]  __
#      > `' <      \ \/  \/ /  [  |  | '' <  [  |
#    _/ /'`\ \_     \  /\  /    | |  | |`\ \  | |
#   |____||____|     \/  \/    [___][__|  \_][___]

LABEL org.opencontainers.image.authors='XWiki Development Team <committers@xwiki.org>'
LABEL org.opencontainers.image.url='https://hub.docker.com/_/xwiki'
LABEL org.opencontainers.image.documentation='https://hub.docker.com/_/xwiki'
LABEL org.opencontainers.image.source='https://github.com/xwiki/xwiki-docker.git'
LABEL org.opencontainers.image.vendor='xwiki.org'
LABEL org.opencontainers.image.licenses='LGPL-2.1'

# Copy Solr cores configuration to their respective locations
COPY --from=builder --chown=1001 /home /var/solr/data
USER 1001
# Start Solr server
CMD ["solr-foreground"]