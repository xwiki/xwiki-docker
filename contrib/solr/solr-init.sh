#!/bin/bash

# Usage:
# - Place the XWiki Solr configuration jar into the same directory as this script
#	- ex. wget http://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-data/10.1/xwiki-platform-search-solr-server-data-10.1.jar
# - ensure that this directory, and it's contents, are owned by the solr user and group, 8983:8983
#	- ex. chown -R 8983:8983 $PARENT_DIRECTORY
# - mount the partent directory of this script to /docker-entrypoint-initdb.d/ when you run the Solr container
#	- ex. add the following to docker run command ... -v $PWD/$PARENT_DIRECTORY:/docker-entrypoint-initdb.d ...
# - At run time, before starting Solr, the container will execute scripts in the /docker-entrypoint-initdb.d/ directory.

cd /docker-entrypoint-initdb.d/
location='/opt/solr/server/solr/'

# Verify the existence of a singular XWiki Solr configuration jar
jars=$(find . -type f -name *.jar | wc -l)
if [ $jars -lt 1 ]; then
	echo 'No XWiki Solr configuration jar found'
	exit 1
elif [ $jars -gt 1 ]; then
	echo 'Too many XWiki Solr configuration jars found, please include only one jar'
	exit 1
fi
# Get the name of the XWiki Solr configuration jar
jar=$(find . -type f -name *.jar)
# Ensure that the Solr directory exists
mkdir -p $location

# Add the XWiki Solr plugin
plugin=$(unzip -Z1 $jar | grep lib.*jar)
unzip -o $jar \
	$plugin \
	-d $location

# Add the XWiki core
core='xwiki/*'
unzip -o $jar \
	$core \
	-d $location