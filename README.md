Provides a full Docker environment for XWiki made up of the following:
* A Docker container running the latest MySQL 5.x database and configured to use UTF8 and be case-insensitive
* A Docker container running the latest Tomcat 8 + Java 8 + XWiki (the version depends on the branch/tag you use)

All source files are under the LGPL 2.1 license.

# Using

You should first install [Docker](https://www.docker.com/) on your machine.

Then there are several options:
1. Get the [sources of this project](https://github.com/xwiki-contrib/xwiki-mysql-tomcat) and build them.
2. Just pull the xwiki image from DockerHub.

## Building ##

This is the simplest solution and the one recommended. Here are the steps:

* Install Git and run `git clone https://github.com/xwiki-contrib/xwiki-mysql-tomcat.git` or download the sources from
the GitHub UI. Then choose the branch or tag that you wish to use:
  * The `master`branch will get you the latest released version of XWiki
  * The `8.x` branch will get you the latest released version of XWiki for the 8.x cycle
  * The `8.4.4` tag will get you exactly XWiki 8.4.4.
  * etc.
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

Here's a minimal Docker Compose file that you could use as an example (full example
[here](https://github.com/xwiki-contrib/xwiki-mysql-tomcat/blob/master/docker-compose-using.yml):

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
      - MYSQL_DATABASE=xwiki
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

# Details

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

# Future

* Setup xinit
* Configure libreoffice
* Solr as external service

# Credits

* Created by Vincent Massol
* Contributions from Ludovic Dubost, Jean Simard
* Some code was copied from https://github.com/ThomasSteinbach/docker_xwiki. Thank you Thomas Steinbach