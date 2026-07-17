#!/bin/bash
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

# Initializes the Solr cores required by XWiki when using a remote (standalone) Solr instance.
#
# Since XWiki 12.2 a remote Solr instance needs several cores (XWiki does not create them itself because the Solr
# REST API is too limited). This script pre-creates them from the two XWiki Solr configuration ZIPs.
#
# Usage:
# - Download the two configuration ZIPs matching your XWiki version and place them next to this script:
#     - the search core config:  xwiki-platform-search-solr-server-core-search-<version>.zip
#     - the minimal core config: xwiki-platform-search-solr-server-core-minimal-<version>.zip
#   Both are published under https://maven.xwiki.org/releases/org/xwiki/platform/ (one directory per artifact).
# - Ensure that this directory, and its contents, are owned by the solr user and group, 8983:8983
#     - ex. chown -R 8983:8983 $PARENT_DIRECTORY
# - Mount the parent directory of this script to /docker-entrypoint-initdb.d/ when you run the Solr container
#     - ex. add the following to the docker run command ... -v $PWD/$PARENT_DIRECTORY:/docker-entrypoint-initdb.d ...
# - At run time, before starting Solr, the container will execute scripts in the /docker-entrypoint-initdb.d/ directory.

set -e

initdir='/docker-entrypoint-initdb.d'
datadir='/var/solr/data'
# XWiki prefixes its Solr cores to avoid collisions. It matches the "solr.remote.corePrefix" xwiki.properties
# property (default "xwiki"). Override with XWIKI_SOLR_CORE_PREFIX if you changed that property.
prefix="${XWIKI_SOLR_CORE_PREFIX:-xwiki}"

cd "$initdir"

# XWiki names its cores "<prefix>_<core>_<solrMajorVersion>" (e.g. xwiki_search_9), so we need the Solr major version.
solrVersion=$(solr version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
major="${solrVersion%%.*}"
if [ -z "$major" ]; then
	echo 'Unable to determine the Solr major version'
	exit 1
fi

# Locate the two configuration ZIPs (the search core uses the full config, the other cores use the minimal one).
searchZip=$(find . -maxdepth 1 -type f -name '*server-core-search*.zip' | head -1)
minimalZip=$(find . -maxdepth 1 -type f -name '*server-core-minimal*.zip' | head -1)
if [ -z "$searchZip" ]; then
	echo 'No XWiki Solr search core configuration ZIP found (*server-core-search*.zip)'
	exit 1
fi
if [ -z "$minimalZip" ]; then
	echo 'No XWiki Solr minimal core configuration ZIP found (*server-core-minimal*.zip)'
	exit 1
fi

# Creates a Solr core by unzipping a configuration ZIP into its data directory. The ZIPs ship an empty
# "core.properties" file, which makes Solr use the directory name as the core name (core discovery).
# $1 - the XWiki core name (e.g. search, events)
# $2 - the configuration ZIP to unzip
create_core() {
	local core="$1"
	local zip="$2"
	local dir="$datadir/${prefix}_${core}_${major}"
	if [ -d "$dir" ]; then
		echo "Solr core [$(basename "$dir")] already exists, skipping"
		return
	fi
	echo "Creating Solr core [$(basename "$dir")]"
	mkdir -p "$dir"
	unzip -o -q "$zip" -d "$dir"
}

create_core 'search' "$searchZip"
create_core 'extension_index' "$minimalZip"
create_core 'ratings' "$minimalZip"
create_core 'events' "$minimalZip"
