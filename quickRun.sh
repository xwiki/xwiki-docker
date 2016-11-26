#!/bin/sh
XWIKI_PORT=8080
echo "XWiki will be started at local port $XWIKI_PORT. Edit quickRun.sh to change it"
echo "Building docker container. This will take some time at first run"
docker build -t xwiki .
# The next two lines are necessary to authorize access to your data to the container
# you will be asked for sudo access
echo "Creating data container"
docker run -it -d --name xwiki-data xwiki
echo "Stopping data container"
docker stop xwiki-data
echo "Starting Container xwiki"
echo "Visit http://localhost:$XWIKI_PORT after startup"
docker run --volumes-from xwiki-data -p $XWIKI_PORT:8080 xwiki
