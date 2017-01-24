Provides several full Docker environments for running XWiki.

The following configurations are currently supported:
* Two Docker containers with one container for running latest MySQL 5.x database (configured to use UTF8 and be 
case-insensitive) and another container for running the latest Tomcat 8 + Java 8 + XWiki (the version depends on the 
branch/tag you use).

All source files are under the LGPL 2.1 license.

# Assumptions

The goal is to provide a production-ready XWiki system running in Docker. This why:
* The OS is based on Debian and not on some smaller-footprint distribution like Alpine
* Several containers are used with Docker Compose: one for the DB and another for XWiki + Servlet container. This 
  allows the ability to run them on different machines for example. 

# Using

You should first install [Docker](https://www.docker.com/) on your machine.

Then there are several options:

1. Get the [sources of this project](https://github.com/xwiki-contrib/docker-xwiki) and build them.
2. Just pull the xwiki image from DockerHub.

## Building ##

This is the simplest solution and the one recommended. Here are the steps:

* Install Git and run `git clone https://github.com/xwiki-contrib/docker-xwiki.git` or download the sources from
the GitHub UI. Then choose the branch or tag that you wish to use:
  * The `master`branch will get you the latest released version of XWiki
  * The `8.x` branch will get you the latest released version of XWiki for the 8.x cycle
  * The `8.4.4` tag will get you exactly XWiki 8.4.4.
  * etc.
* Go the directory corresponding to the configuration you wish to build, for example: `cd xwiki-mysql-tomcat`.
* Run `docker-compose up` 
* Start a browser and point it to `http://localhost:8080`

Note that if you want to set a custom version of XWiki you can checkout `master` and edit the `env` file and set the 
values you need in there. It's also possible to override them on the command line with 
`docker-compose run -e "XWIKI_VERSION=8.4.4"`.

Note that `docker-compose up` will automatically build the XWiki image on the first run. If you need to rebuild it 
you can issue `docker-compose up --build`. You can also build the image with
`docker build . -t xwiki-mysql-tomcat:latest` for example.

## Pulling existing image ##

This is a bit more complex since you need to have 2 docker containers running: one for XWiki and one for the database.

Here's a minimal Docker Compose file using MySQL that you could use as an example (full example
[here](https://github.com/xwiki-contrib/docker-xwiki/blob/master/xwiki-mysql-tomcat/docker-compose-using.yml)):

```
version: '2'
services:
  web:
    image: "xwiki/xwiki-mysql-tomcat:latest"
    depends_on:
      - db
    ports:
      - "8080:8080"
    volumes:
      - xwiki-data:/var/lib/xwiki
    environment:
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
  db:
    image: "mysql:5"
    volumes:
      - ./mysql/xwiki.cnf:/etc/mysql/conf.d/xwiki.cnf
      - mysql-data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
volumes:
  mysql-data: {}
  xwiki-data: {}
```

# Details for xwiki-mysql-tomcat

## Configuration Options

The first time you create a container out of the xwiki image, a shell script (/usr/local/bin/start_xwiki.sh`) is 
executed in the container to setup some configuration. The following environment variables can be passed:

* `MYSQL_USER`: The MySQL user name used by XWiki to read/write to the DB.
* `MYSQL_PASSWORD`: The MySQL user password used by XWiki to read/write to the DB.

## Miscellaneous

Volumes:
* Two volumes are created:
  * A volume named `<prefix>_mysql-data` that contains the database data.
  * A volume named `<prefix>_xwiki-data` that contains XWiki's permanent directory.
* To find out where those volumes are located on your local host machine you can inspect them with `docker volume inspect <volume name>`. To find the volume name, you can list all volumes with `docker volume ls`. 
* Note that on Mac OSX, Docker runs inside the xhyve VM and thus the paths you get when inspecting the volumes are relative to this. Thus, you need to get into that VM if you need to access the volume data. 

MySQL:
* To issue some mysql commands:
 * Find the container id with `docker ps` 
 * Execute bash in the mysql container: `docker exec -it <containerid> bash -l`
 * Once inside the mysql container execute the `mysql` command: `mysql --user=xwiki --password=xwiki`

# Support

* If you wish to raise an issue or an idea of improvement use [XWiki Docker JIRA project](http://jira.xwiki.org/browse/XDOCKER)
* If you have questions, use the [XWiki Users Mailing List/Forum](http://dev.xwiki.org/xwiki/bin/view/Community/MailingLists) or use the [XWiki IRC channel](http://dev.xwiki.org/xwiki/bin/view/Community/IRC)

# Contribute

* If you wish to help out on the code, please send Pull Requests on [XWiki Docker GitHub project](https://github.com/xwiki-contrib/docker-xwiki)

# Credits

* Created by Vincent Massol
* Contributions from Ludovic Dubost, Jean Simard
* Some code was copied from https://github.com/ThomasSteinbach/docker_xwiki. Thank you Thomas Steinbach
