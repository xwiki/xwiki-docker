# Introduction

This project contains the Dockerfile for building a container running XWiki 7.0 on Tomcat with MySQL as a database.

# Building

Just run `docker build -t xwiki .` and you should have your image ready in your docker repository.

# Automatic Running

Launch quickRun.sh

Once the container is started, you can open a browser and connect to `http://localhost:8080/xwiki`

# Manual Running

When running the container you first need to create a data container and then stop it

docker run -it -d --name xwiki-data xwiki
docker stop xwiki-data

And then run the container specifying the data container for volumes

docker run --volumes-from xwiki-data -p 8080:8080 xwiki

Running without a data container will make the data stored in the wiki dissapear when the container is stopped.
Not specifying the port mapping will make XWiki inaccessible from the host.

Once the container is started, you can open a browser and connect to `http://localhost:8080/xwiki`

# Disclaimer

I still need to find a way to shut things down gracefully, so do not use this in production :)

