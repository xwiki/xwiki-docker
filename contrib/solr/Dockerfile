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

# The official Solr image doesn't ship "unzip", which "solr-init.sh" needs to extract the XWiki Solr configuration
# ZIPs into the Solr cores. This image simply adds it. Adjust the Solr major version to match your XWiki version
# (XWiki supports the current and previous Solr major versions).
FROM solr:9

USER root
RUN apt-get update && \
    apt-get install --yes --no-install-recommends unzip && \
    rm -rf /var/lib/apt/lists/*
USER solr

# XWiki's search core schema relies on language analyzers (e.g. the Polish "stempelPolishStem" filter) shipped in
# Solr's optional "analysis-extras" module. Without it the search core fails to load with an SPI class error.
ENV SOLR_MODULES=analysis-extras
