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

# Initializes the Solr cores required by XWiki when using a remote (standalone) Solr instance. It reuses the
# standard XWiki Solr core packages (baked into the image under /opt/xwiki-solr, see the Dockerfile), which are
# designed to work with a standard Solr install.
#
# Usage:
# - Build the Solr image from the Dockerfile next to this script (it downloads the core packages and copies this
#   script into /docker-entrypoint-initdb.d). Pass "--build-arg XWIKI_VERSION=<version>" to match your XWiki version.
# - Run that image: on startup, before Solr starts, the container executes scripts in /docker-entrypoint-initdb.d/,
#   so this script runs and creates any missing core in the (possibly mounted) Solr home.

set -e

debdir='/opt/xwiki-solr'
datadir='/var/solr/data'

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for deb in "$debdir"/*.deb; do
	# "dpkg -x" unpacks the package payload without registering it (there is no dpkg database in the Solr image).
	# We stage it, then copy only the missing cores so re-runs (the init scripts run on every start) don't clobber
	# an already-populated core in a persisted volume.
	dpkg -x "$deb" "$tmp"
	for core in "$tmp"/var/solr/data/*/; do
		name="$(basename "$core")"
		if [ -d "$datadir/$name" ]; then
			echo "Solr core [$name] already exists, skipping"
		else
			echo "Creating Solr core [$name]"
			cp -a "$core" "$datadir/$name"
		fi
	done
	rm -rf "$tmp/var"
done
