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

# Adjust the Solr major version to match your XWiki version (XWiki supports the current and previous Solr major
# versions). It must stay consistent with the "_<solrMajorVersion>" suffix baked into the core packages downloaded
# below (the packages targeting Solr 9 lay their cores under ".../xwiki_<core>_9").
FROM solr:9

# The XWiki version whose Solr cores to install. It must match the version of XWiki you run. Override at build time
# with "--build-arg XWIKI_VERSION=<version>".
ARG XWIKI_VERSION=18.5.0

USER root

# Download the pre-built XWiki Solr core packages so that "solr-init.sh" can lay them into the Solr home on startup.
# XWiki publishes one Debian package per core (search, events, ratings, extension_index); each unpacks to
# "/var/solr/data/xwiki_<core>_9" with its "core.properties", full "conf/" and the required "lib/" jars, which is
# exactly what Solr's core discovery expects. Reusing these packages avoids reproducing the core layout by hand.
RUN apt-get update && \
    apt-get install --yes --no-install-recommends ca-certificates curl && \
    mkdir -p /opt/xwiki-solr && \
    base='https://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform' && \
    for core in search events ratings extension_index; do \
        artifact="xwiki-platform-distribution-debian-solr-core-${core}"; \
        curl -fSL -o "/opt/xwiki-solr/${artifact}.deb" \
            "${base}/${artifact}/${XWIKI_VERSION}/${artifact}-${XWIKI_VERSION}.deb"; \
    done && \
    rm -rf /var/lib/apt/lists/*

# Run the core initialization on container startup (Solr executes the scripts in /docker-entrypoint-initdb.d/ before
# starting). Baking it in (rather than bind-mounting it) means running the image needs no init directory mount.
COPY solr-init.sh /docker-entrypoint-initdb.d/solr-init.sh
RUN chmod +x /docker-entrypoint-initdb.d/solr-init.sh

USER solr

# XWiki's search core schema relies on language analyzers (e.g. the Polish "stempelPolishStem" filter) shipped in
# Solr's optional "analysis-extras" module (the core packages do not, and cannot, bundle it). Without it the search
# core fails to load with an SPI class error.
ENV SOLR_MODULES=analysis-extras
