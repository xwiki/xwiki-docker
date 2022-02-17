# What is XWiki

[XWiki](https://xwiki.org/) is a free wiki software platform written in Java with a design emphasis on extensibility. XWiki is an enterprise wiki. It includes WYSIWYG editing, OpenDocument based document import/export, semantic annotations and tagging, and advanced permissions management.

As an application wiki, XWiki allows for the storing of structured data and the execution of server side script within the wiki interface. Scripting languages including Velocity, Groovy, Python, Ruby and PHP can be written directly into wiki pages using wiki macros. User-created data structures can be defined in wiki documents and instances of those structures can be attached to wiki documents, stored in a database, and queried using either Hibernate query language or XWiki's own query language.

[XWiki.org's extension wiki](https://extensions.xwiki.org/) is home to XWiki extensions ranging from [code snippets](https://snippets.xwiki.org/) which can be pasted into wiki pages to loadable core modules. Many of XWiki Enterprise's features are provided by extensions which are bundled with it.

![logo](https://www.xwiki.org/xwiki/bin/view/Main/Logo?xpage=plain&act=svg&finput=logo-xwikiorange.svg&foutput=logo-xwikiorange.png&width=200)

# Table of contents

<!-- generated with pandoc -f gfm --toc -o readme-toc.md README.md -->

- [Introduction](#introduction)
- [How to use this image](#how-to-use-this-image)
    -	[Pulling existing image](#pulling-an-existing-image)
        -	[Using docker run](#using-docker-run)
        -	[Using docker-compose](#using-docker-compose)
        -	[Using Docker Swarm](#using-docker-swarm)
    -	[Using an external Solr service](#using-an-external-solr-service)
        -	[Preparing Solr container](#preparing-solr-container)
        -	[Docker run example](#docker-run-example)
        -	[Docker Compose example](#docker-compose-example)
    -	[Configuring Tomcat](#configuring-tomcat)
    -	[Building](#building)
- [Upgrading XWiki](#upgrading-xwiki)
- [Details for the xwiki image](#details-for-the-xwiki-image)
    -	[Configuration Options](#configuration-options)
    -	[Passing JVM options](#passing-jvm-options)
    -	[Configuration Files](#configuration-files)
    -	[Miscellaneous](#miscellaneous)
- [For Maintainers](#for-maintainers)
    -	[Update Docker Images](#update-docker-images)
    -	[Testing Docker Images](#testing-docker-images)
    -	[Clean Up](#clean-up)
- [License](#license)
- [Support](#support)
- [Contribute](#contribute)
- [Credits](#credits)

# Introduction

The goal is to provide a production-ready XWiki system running in Docker. This is why:

-	The OS is based on Debian and not on some smaller-footprint distribution like Alpine
-	Several containers are used with Docker Compose: one for the DB and another for XWiki + Servlet container. This allows the ability to run them on different machines for example. 

# How to use this image

You should first install [Docker](https://www.docker.com/) on your machine.

Then there are several options:

1.	Pull the xwiki image from DockerHub.
2.	Get the [sources of this project](https://github.com/xwiki-contrib/docker-xwiki) and build them.

## Pulling an existing image

You need to run 2 containers:

-	One for the XWiki image
-	One for the database image to which XWiki connects to

### Using docker run

Start by creating a dedicated docker network:

```console
docker network create -d bridge xwiki-nw
```

Then run a container for the database and make sure it's configured to use an UTF8 encoding. The following databases are supported out of the box:

-	MySQL
-	MariaDB
-	PostgreSQL

#### Starting MySQL

We will bind mount two local directories to be used by the MySQL container:
-	one to be used at database initialization to set permissions (see below), 
-	another to contain the data put by XWiki inside the MySQL database, so that when you stop and restart MySQL you don't find yourself without any data.

For example:
-	`/my/path/mysql-init`
-	`/my/path/mysql`

You need to make sure these directories exist, and then create a file under the `/my/path/mysql-init` directory (you can name it the way you want, for example `init.sql`), with the following content:

```sql
grant all privileges on *.* to xwiki@'%'
```

This will provide enough permissions for the `xwiki` user to create new schemas which is required to be able to create sub-wikis. 

Note: Make sure the directories you are mounting into the container are fully-qualified, and aren't relative paths.

```console
docker run --net=xwiki-nw --name mysql-xwiki -v /my/path/mysql:/var/lib/mysql -v /my/path/mysql-init:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=xwiki -e MYSQL_USER=xwiki -e MYSQL_PASSWORD=xwiki -e MYSQL_DATABASE=xwiki -d mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_bin --explicit-defaults-for-timestamp=1
```

You should adapt the command line to use the passwords that you wish for the MySQL root password and for the `xwiki` user password (make sure to also change the GRANT command).

Notes:

-   If you're using MySQL8, you also need to configure the `mysql_native_password` authentication plugin the native password mechanism that XWiki uses to connect:

    ```console
    docker run --net=xwiki-nw --name mysql-xwiki -v /my/path/mysql:/var/lib/mysql -v /my/path/mysql-init:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=xwiki -e MYSQL_USER=xwiki -e MYSQL_PASSWORD=xwiki -e MYSQL_DATABASE=xwiki -d mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_bin --explicit-defaults-for-timestamp=1 --default-authentication-plugin=mysql_native_password
    ```

-   If you want to use `utf8` instead of `utf8mb4` (you won't have emojis though), you could use instead: `character-set-server=utf8 --collation-server=utf8_bin`.
-   The `explicit-defaults-for-timestamp` parameter was introduced in MySQL 5.6.6 and will thus work only for that version and beyond. If you are using an older MySQL version, please use the following instead:

    ```console
    docker run --net=xwiki-nw --name mysql-xwiki -v /my/path/mysql:/var/lib/mysql -v /my/path/mysql-init:/docker-entrypoint-initdb.d -e MYSQL_ROOT_PASSWORD=xwiki -e MYSQL_USER=xwiki -e MYSQL_PASSWORD=xwiki -e MYSQL_DATABASE=xwiki -d mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_bin
    ```

#### Starting MariaDB

This is exactly similar to starting MySQL and you should thus follow exactly the same steps as for MySQL. The only thing to change is the docker image for MariaDB: instead of `mysql:<tag>`, use `mariadb:<tag>`. For example: `mariadb:10.5`.

Full command example:

```console
docker run --net=xwiki-nw --name mariadb-xwiki -v /my/path/mariadb:/var/lib/mysql -v /my/path/mariadb-init:/docker-entrypoint-initdb.d -e MARIADB_ROOT_PASSWORD=xwiki -e MARIADB_USER=xwiki -e MARIADB_PASSWORD=xwiki -e MARIADB_DATABASE=xwiki -d mariadb:10.5 --collation-server=utf8mb4_bin --explicit-defaults-for-timestamp=1
```

#### Starting PostgreSQL

We will bind mount a local directory to be used by the PostgreSQL container to contain the data put by XWiki inside the database, so that when you stop and restart PostgreSQL you don't find yourself without any data.  For example:

-	`/my/path/postgres`

You need to make sure this directory exists, before proceeding.

Note Make sure the directory you specify is specified with the fully-qualified path, not a relative path.

```console
docker run --net=xwiki-nw --name postgres-xwiki -v /my/path/postgres:/var/lib/postgresql/data -e POSTGRES_ROOT_PASSWORD=xwiki -e POSTGRES_USER=xwiki -e POSTGRES_PASSWORD=xwiki -e POSTGRES_DB=xwiki -e POSTGRES_INITDB_ARGS="--encoding=UTF8" -d postgres:9.5
```

You should adapt the command line to use the passwords that you wish for the PostgreSQL root password and for the xwiki user password.

#### Starting XWiki

We will also bind mount a local directory for the XWiki permanent directory (contains application config and state), for example:

-	`/my/path/xwiki`

Note Make sure the directory you specify is specified with the fully-qualified path, not a relative path.

Ensure this directory exists, and then run XWiki in a container by issuing one of the following command.

For MySQL:

```console
docker run --net=xwiki-nw --name xwiki -p 8080:8080 -v /my/path/xwiki:/usr/local/xwiki -e DB_USER=xwiki -e DB_PASSWORD=xwiki -e DB_DATABASE=xwiki -e DB_HOST=mysql-xwiki xwiki:lts-mysql-tomcat
```

For MariaDB:
```console
docker run --net=xwiki-nw --name xwiki -p 8080:8080 -v /my/path/xwiki:/usr/local/xwiki -e DB_USER=xwiki -e DB_PASSWORD=xwiki -e DB_DATABASE=xwiki -e DB_HOST=mariadb-xwiki xwiki:stable-mariadb
```

For PostgreSQL:

```console
docker run --net=xwiki-nw --name xwiki -p 8080:8080 -v /my/path/xwiki:/usr/local/xwiki -e DB_USER=xwiki -e DB_PASSWORD=xwiki -e DB_DATABASE=xwiki -e DB_HOST=postgres-xwiki xwiki:lts-postgres-tomcat
```

Be careful to use the same DB username, password and database names that you've used on the first command to start the DB container. Also, please don't forget to add a `-e DB_HOST=` environment variable with the name of the previously created DB container so that XWiki knows where its database is.

At this point, XWiki should start in interactive blocking mode, allowing you to see logs in the console. Should you wish to run it in "detached mode", just add a "-d" flag in the previous command.

```console
docker run -d --net=xwiki-nw ...
```

### Using docker-compose

Another solution is to use the Docker Compose files we provide.

#### For MySQL on Tomcat

-	`wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mysql-tomcat/mysql/xwiki.cnf`: This will download the MySQL configuration (UTF8, etc)
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mysql-tomcat/mysql/xwiki.cnf -o xwiki.cnf`
-	`wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mysql-tomcat/mysql/init.sql`: This will download some SQL to execute at startup for MySQL
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mysql-tomcat/mysql/init.sql -o init.sql`
-	`wget -O docker-compose.yml https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mysql-tomcat/docker-compose.yml`
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mysql-tomcat/docker-compose.yml -o docker-compose.yml`
-	You can edit the compose file retrieved to change the default username/password and other environment variables.
-	`docker-compose up`

For reference here's a minimal Docker Compose file using MySQL that you could use as an example (full example [here](https://github.com/xwiki/xwiki-docker/blob/master/14/mysql-tomcat/docker-compose.yml)):

```yaml
version: '2'
networks:
  bridge:
    driver: bridge
services:
  web:
    image: "xwiki:lts-mysql-tomcat"
    container_name: xwiki-mysql-tomcat-web
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_HOST=xwiki-mysql-db
    volumes:
      - xwiki-data:/usr/local/xwiki
    networks:
      - bridge
  db:
    image: "mysql:5"
    container_name: xwiki-mysql-db
    volumes:
      - ./xwiki.cnf:/etc/mysql/conf.d/xwiki.cnf
      - mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
    networks:
      - bridge
volumes:
  mysql-data: {}
  xwiki-data: {}
```

#### For MariaDB on Tomcat

-	`wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mariadb-tomcat/mariadb/xwiki.cnf`: This will download the MAriaDB configuration (UTF8, etc)
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mariadb-tomcat/mariadb/xwiki.cnf -o xwiki.cnf`
-	`wget https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mariadb-tomcat/mariadb/init.sql`: This will download some SQL to execute at startup for MariaDB
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mariadb-tomcat/mariadb/init.sql -o init.sql`
-	`wget -O docker-compose.yml https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mariadb-tomcat/docker-compose.yml`
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/mariadb-tomcat/docker-compose.yml -o docker-compose.yml`
-	You can edit the compose file retrieved to change the default username/password and other environment variables.
-	`docker-compose up`

For reference here's a minimal Docker Compose file using MariaDB that you could use as an example (full example [here](https://github.com/xwiki/xwiki-docker/blob/master/14/mariadb-tomcat/docker-compose.yml)):

```yaml
version: '2'
networks:
  bridge:
    driver: bridge
services:
  web:
    image: "xwiki:lts-mariadb-tomcat"
    container_name: xwiki-mariadb-tomcat-web
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_HOST=xwiki-mariadb-db
    volumes:
      - xwiki-data:/usr/local/xwiki
    networks:
      - bridge
  db:
    image: "mariadb:10.5"
    container_name: xwiki-mariadb-db
    volumes:
      - ./xwiki.cnf:/etc/mysql/conf.d/xwiki.cnf
      - mariadb-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
    networks:
      - bridge
volumes:
  mariadb-data: {}
  xwiki-data: {}
```

#### For PostgreSQL on Tomcat

-	`wget -O docker-compose.yml https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/postgres-tomcat/docker-compose.yml`
	-	If you don't have `wget` or prefer to use `curl`: `curl -fSL https://raw.githubusercontent.com/xwiki-contrib/docker-xwiki/master/14/postgres-tomcat/docker-compose.yml -o docker-compose.yml`
-	You can edit the compose file retrieved to change the default username/password and other environment variables.
-	`docker-compose up`

For reference here's a minimal Docker Compose file using PostgreSQL that you could use as an example (full example [here](https://github.com/xwiki/xwiki-docker/blob/master/14/postgres-tomcat/docker-compose.yml)):

```yaml
version: '2'
networks:
  bridge:
    driver: bridge
services:
  web:
    image: "xwiki:lts-postgres-tomcat"
    container_name: xwiki-postgres-tomcat-web
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_HOST=xwiki-postgres-db
    volumes:
      - xwiki-data:/usr/local/xwiki
    networks:
      - bridge
  db:
    image: "postgres:13"
    container_name: xwiki-postgres-db
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_ROOT_PASSWORD=xwiki
      - POSTGRES_PASSWORD=xwiki
      - POSTGRES_USER=xwiki
      - POSTGRES_DB=xwiki
      - POSTGRES_INITDB_ARGS="--encoding=UTF8"
    networks:
      - bridge
volumes:
  postgres-data: {}
  xwiki-data: {}
```

### Using Docker Swarm

Here are some examples of using this image with Docker Swarm. These examples leverage additional features of Docker Swarm such as Docker secrets, and Docker configs. As such, these examples require Docker to be in swarm mode.

You can read more about these features and Docker swarm mode here:

-	[Docker swarm mode](https://docs.docker.com/engine/swarm/)
-	[Creating Docker secrets](https://docs.docker.com/engine/reference/commandline/secret_create/)
-	[Creating Docker configs](https://docs.docker.com/engine/reference/commandline/config_create/)

#### MySQL Example

This example presupposes the existence of the Docker secrets `xwiki-db-username`, `xwiki-db-password` and `xwiki-db-root-password`, and the Docker config `xwiki-mysql-config`.

You can create these secrets and configs with the following:

-	`echo ${MY_XWIKI_USER:-xwiki} | docker secret create xwiki-db-username -`
-	`echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) | docker secret create xwiki-db-password -`
-	`echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) | docker secret create xwiki-db-root-password -`
-	`docker config create xwiki-mysql-config /path/to/mysql/xwiki.cnf`

To deploy this example, save the following YAML as `xwiki-stack.yaml`, then run:

-	`docker stack deploy -c xwiki-stack.yaml xwiki`

```yaml
version: '3.3'
services:
  web:
    image: "xwiki:lts-mysql-tomcat"
    ports:
      - "8080:8080"
    environment:
      - DB_USER_FILE=/run/secrets/xwiki-db-username
      - DB_PASSWORD_FILE=/run/secrets/xwiki-db-password
      - DB_DATABASE=xwiki
      - DB_HOST=db
    volumes:
      - xwiki-data:/usr/local/xwiki
    secrets:
      - xwiki-db-username
      - xwiki-db-password
  db:
    image: "mysql:5"
    volumes:
      - mysql-data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/xwiki-db-root-password
      - MYSQL_USER_FILE=/run/secrets/xwiki-db-username
      - MYSQL_PASSWORD_FILE=/run/secrets/xwiki-db-password
      - MYSQL_DATABASE=xwiki
    secrets:
      - xwiki-db-username
      - xwiki-db-password
      - xwiki-db-root-password
    configs: 
      - source: mysql-config
        target: /etc/mysql/conf.d/xwiki.cnf
volumes:
  mysql-data:
  xwiki-data:
secrets:
  xwiki-db-username:
    external:
      name: xwiki-db-username
  xwiki-db-password:
    external:
      name: xwiki-db-password
  xwiki-db-root-password:
    external:
      name: xwiki-db-root-password
configs:
  mysql-config:
    external:
      name: xwiki-mysql-config
```

#### PostgreSQL Example

This example presupposes the existence of the Docker secrets `xwiki-db-username`, `xwiki-db-password`, and `xwiki-db-root-password`.

You can create these secrets with the following:

-	`echo ${MY_XWIKI_USER:-xwiki} | docker secret create xwiki-db-username -`
-	`echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) | docker secret create xwiki-db-password -`
-	`echo $(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1) | docker secret create xwiki-db-root-password -`

To deploy this example, save the following YAML as `xwiki-stack.yaml` then run:

-	`docker stack deploy -c xwiki-stack.yaml xwiki`

```yaml
version: '3.3'
services:
  web:
    image: "xwiki:lts-postgres-tomcat"
    ports:
      - "8080:8080"
    environment:
      - DB_USER_FILE=/run/secrets/xwiki-db-username
      - DB_PASSWORD_FILE=/run/secrets/xwiki-db-password
      - DB_DATABASE=xwiki
      - DB_HOST=db
    volumes:
      - xwiki-data:/usr/local/xwiki
    secrets:
      - xwiki-db-username
      - xwiki-db-password
  db:
    image: "postgres:13"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_ROOT_PASSWORD_FILE=/run/secrets/xwiki-db-root-password
      - POSTGRES_USER_FILE=/run/secrets/xwiki-db-username
      - POSTGRES_PASSWORD_FILE=/run/secrets/xwiki-db-password
      - POSTGRES_DB=xwiki
    secrets:
      - xwiki-db-username
      - xwiki-db-password
      - xwiki-db-root-password
volumes:
  postgres-data:
  xwiki-data:
secrets:
  xwiki-db-username:
    external:
      name: xwiki-db-username
  xwiki-db-password:
    external:
      name: xwiki-db-password
  xwiki-db-root-password:
    external:
      name: xwiki-db-root-password
```

## Using an external Solr service

From the [XWiki Solr Search API documentation](https://extensions.xwiki.org/xwiki/bin/view/Extension/Solr%20Search%20API):

> By default XWiki ships with an embedded Solr. This is mostly for ease of use but the embedded instance is not really recommended by the Solr team so you might want to externalize it when starting to have a wiki with a lots of pages. Solr is using a lot of memory and a standalone Solr instance is generally better in term of speed than the embedded one. It should not be much noticeable in a small wiki but if you find yourself starting to have memory issues and slow search results you should probably try to install and setup an external instance of Solr using the guide.
>
> Also the speed of the drive where the Solr index is located can be very important because Solr/Lucene is quite filesystem intensive. For example putting it in a SSD might give a noticeable boost.
>
> You can also find more Solr-specific performance details on https://wiki.apache.org/solr/SolrPerformanceProblems. Standalone Solr also comes with a very nice UI, along with monitoring and test tools.

This image provides the configuration parameters `INDEX_HOST` and `INDEX_PORT` which are used to configure `xwiki.properties` with:

```data
solr.type=remote  
solr.remote.url=http://$INDEX_HOST:$INDEX_PORT/solr/xwiki
```

#### Preparing Solr container

The simplest way to create an external Solr service is using the [official Solr image](https://hub.docker.com/_/solr/).

-	Select the appropriate XWiki Solr configuration JAR from [here](https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-search-solr-server-data/) (Note: it's usually better to synchronize it with your version of XWiki)
-	Place this JAR in a directory along side `solr-init.sh` that you can fetch from the [docker-xwiki repository](https://github.com/xwiki-contrib/docker-xwiki/tree/master/contrib/solr)
-	Ensure that this directory is owned by the Solr user and group `chown -R 8983:8983 /path/to/solr/init/directory`
-	Launch the Solr container and mount this directory at `/docker-entrypoint-initdb.d`
-	This will execute `solr-init.sh` on container startup and prepare the XWiki core with the contents from the given JAR
-	If you want to persist the Solr index outside of the container with a bind mount, make sure that that directory is owned by the Solr user and group `chown 8983:8983 /my/path/solr`

#### Docker run example

Start your chosen database container normally using the docker run command above, this example happens to assume MySQL was chosen.

The command below will configure the Solr container to initialize based on the contents of `/path/to/solr/init/directory/` and save its data on the host in a `/my/path/solr` directory:

```console
docker run \
  --net=xwiki-nw \
  --name solr-xwiki \
  -v /path/to/solr/init/directory:/docker-entrypoint-initdb.d \
  -v /my/path/solr:/opt/solr/server/solr/xwiki \
  -d solr:8
```

Then start the XWiki container, the below command is nearly identical to that specified in the Starting XWiki section above, except that it includes the `-e INDEX_HOST=` environment variable which specifies the hostname of the Solr container.

```console
docker run \
  --net=xwiki-nw \
  --name xwiki \
  -p 8080:8080 \
  -v /my/path/xwiki:/usr/local/xwiki \
  -e DB_USER=xwiki \
  -e DB_PASSWORD=xwiki \
  -e DB_DATABASE=xwiki \
  -e DB_HOST=mysql-xwiki \
  -e INDEX_HOST=solr-xwiki \
  -d xwiki:lts-mysql-tomcat
```

#### Docker Compose example

The below compose file assumes that `./solr` contains `solr-init.sh` and the configuration JAR file.

```yaml
version: '2'
networks:
  bridge:
    driver: bridge
services:
  web:
    image: "xwiki:lts-mysql-tomcat"
    container_name: xwiki-web
    depends_on:
      - db
      - index
    ports:
      - "8080:8080"
    environment:
      - XWIKI_VERSION=xwiki
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_DATABASE=xwiki
      - DB_HOST=xwiki-db
      - INDEX_HOST=xwiki-index
    volumes:
      - xwiki-data:/usr/local/xwiki
    networks:
      - bridge
  db:
    image: "mysql:5"
    container_name: xwiki-db
    volumes:
      - ./mysql/xwiki.cnf:/etc/mysql/conf.d/xwiki.cnf
      - mysql-data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=xwiki
      - MYSQL_USER=xwiki
      - MYSQL_PASSWORD=xwiki
      - MYSQL_DATABASE=xwiki
    networks:
      - bridge
  index:
    image: "solr:8"
    container_name: xwiki-index
    volumes:
      - ./solr:/docker-entrypoint-initdb.d
      - solr-data:/opt/solr/server/solr
    networks:
      - bridge
volumes:
  mysql-data: {}
  xwiki-data: {}
  solr-data: {}
```

## Configuring Tomcat

If you need to configure Tomcat (for example to setup a reverse proxy configuration), you'll need to mount the Tomcat configuration directory (`/usr/local/tomcat/conf`) inside the image onto your local host.  

If you want to modify the existing configuration rather than provide a brand new one, you'll need to use `docker cp` to copy the configuration from the container to your local host.

Here are some example steps you can follow:

-   Create a docker container from the XWiki image with `docker create`.
    -   Example: `docker create --name xwiki xwiki:lts-mysql-tomcat`.
-   Copy the Tomcat configuration from the container to the host to start with some existing configuration files, using `docker cp`.
    -   Example: `sudo docker cp xwiki:/usr/local/tomcat/conf /tmp/tomcat`.
-   Modify the Tomcat configuration locally to bring the changes you need.
-   Delete the created XWiki container since it was only used to copy the configuration files and we'll need to create a new one with different parameters.
    -   Example: `docker rm xwiki`.
-   Run the container with the Tomcat mount and the other parameters.
    -   Example: `docker run --net=xwiki-nw --name xwiki -p 8080:8080 -v /tmp/xwiki:/usr/local/xwiki -v /tmp/tomcat:/usr/local/tomcat/conf -e DB_USER=xwiki -e DB_PASSWORD=xwiki -e DB_DATABASE=xwiki -e DB_HOST=mysql-xwiki xwiki:lts-mysql-tomcat`

## Building

This allows you to rebuild the XWiki docker image locally. Here are the steps:

-	Install Git and run `git clone https://github.com/xwiki-contrib/docker-xwiki.git` or download the sources from the GitHub UI. Then go to the directory corresponding to the docker tag you wish to use. For example: `cd 13/mysql-tomcat`
	-	The `13/mysql-tomcat` directory will get you the latest released XWiki version of the 13.x cycle running on Tomcat and for MySQL.
	-	The `13/postgres-tomcat` directory will get you the latest released XWiki version of the 13.x cycle running on Tomcat and for MySQL.
	-	The `12/mysql-tomcat` directory will get you the latest released XWiki version of the 12.x cycle running on Tomcat and for MySQL.
	-	etc.
-	Run `docker-compose up`
-	Start a browser and point it to `http://localhost:8080`

Note that if you want to set a custom version of XWiki you can edit the `.env` file and set the values you need in there. It's also possible to override them on the command line with `docker-compose run -e "XWIKI_VERSION=12.10.10"`.

Note that `docker-compose up` will automatically build the XWiki image on the first run. If you need to rebuild it you can issue `docker-compose up --build`. You can also build the image with `docker build . -t xwiki-mysql-tomcat:latest` for example.

You can also just build the image by issuing `docker build -t xwiki .` and then use the instructions from above to start XWiki and the database using `docker run ...`.

# Upgrading XWiki

You've installed an XWiki docker image and used it and now comes the time when you'd like to upgrade XWiki to a newer version.

If you've followed the instructions above you've mapped the XWiki permanent directory to a local directory on your host.

All you need to do to upgrade is to stop the running XWiki container and start the new version of it that you want to upgrade to. You should keep your DB container running.

Note that your current XWiki configuration files (`xwiki.cfg`, `xwiki.properties` and `hibernate.cfg.xml`) will be preserved. 

You should always check the [Release Notes](https://www.xwiki.org/xwiki/bin/view/ReleaseNotes/) for all releases that happened between your current version and the new version you're upgrading to, as there could be some manual steps to perform (such as updating your XWiki configuration files).

# Details for the xwiki image

## Configuration Options

The first time you create a container out of the xwiki image, a shell script (`/usr/local/bin/docker-entrypoint.sh`) is executed in the container to setup some configuration. The following environment variables can be passed:

-	`DB_USER`: The user name used by XWiki to read/write to the DB.
-	`DB_PASSWORD`: The user password used by XWiki to read/write to the DB.
-	`DB_DATABASE`: The name of the XWiki database to use/create.
-	`DB_HOST`: The name of the host (or docker container) containing the database. Default is "db".
-	`INDEX_HOST`: The hostname of an externally configured Solr instance. Defaults to "localhost", and configures an embedded Solr instance.
-	`INDEX_PORT`: The port used by an externally configured Solr instance. Defaults to 8983.
-   `CONTEXT_PATH`: The name of the context path under which XWiki will be deployed in Tomcat. If not specified then it'll be deployed as ROOT.
    -   If you had set this environment property and later on, recreate the XWiki container without passing it (i.e you wish to deploy XWiki as ROOT again), the you'll need to edit the `xwiki.cfg` file in your mapped local permanent directory and set `xwiki.webapppath=`.
    
In order to support [Docker secrets](https://docs.docker.com/engine/swarm/secrets/), these configuration values can also be given to the container as files containing that value.

-	`DB_USER_FILE`: The location, inside the container, of a file containing the value for `DB_USER`
-	`DB_PASSWORD_FILE`: The location, inside the container, of a file containing the value for `DB_PASSWORD`
-	`DB_DATABASE_FILE`: The location, inside the container, of a file containing the value for `DB_DATABASE`
-	`DB_HOST_FILE`: The location, inside the container, of a file containing the value for `DB_HOST`
-	`INDEX_HOST_FILE`: The location, inside the container, of a file containing the value for `INDEX_HOST`
-	`INDEX_PORT_FILE`: The location, inside the container, of a file containing the value for `INDEX_PORT`

*Note:* For each configuration value, the normal environment variable and \_FILE environment variable are mutually exclusive. Providing values for both variables will result in an error.

The main XWiki configuration files (`xwiki.cfg`, `xwiki.properties` and `hibernate.cfg.xml`) are available in the mapped local directory for the permanent directory on your host.

If you need to perform some advanced configuration, you can get a shell inside the running XWiki container by issuing the following (but note that these won't be saved if you remove the container):

```console
docker exec -it <xwiki container id> bash -l
```

## Passing JVM options

It's possible to pass JVM options to Tomcat by defining the `JAVA_OPTS` environment property.

For example to debug XWiki, you could use:

```console
docker run --net=xwiki-nw --name xwiki -p 8080:8080 -v xwiki:/usr/local/xwiki -e DB_USER=xwiki -e DB_PASSWORD=xwiki -e DB_DATABASE=xwiki -e DB_HOST=mysql-xwiki -e JAVA_OPTS="-Xdebug -Xnoagent -Djava.compiler=NONE -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005" -p 5005:5005 xwiki
```

Notice the mapping of the port with `p 5005:5005` which expose the port and thus allows you to debug XWiki from within your IDE for example.

## Configuration Files

There are 3 important configuration files for XWiki that you may want to modify:
-	`xwiki.cfg`
-	`xwiki.properties`
-	`hibernate.cfg.xml`

In order to make it easy to modify them outside the container, the XWiki image does the following:

-	On the first XWiki container start, these 3 files are copied from inside the container (they're located in `[xwiki servlet context]/WEB-INF`) to your local permanent directory (that you've mapped as a volume when you're executing the XWiki container). This creates a timestamp file named `/usr/local/tomcat/webapps/[xwiki servlet context]/.first_start_completed` in the XWiki container.
-	On the next XWiki container starts, if the timestamp file exists, then, the 3 files are copied from your local permanent directory inside the XWiki container (overwriting any default config files there), so that your config if used. If one of these files doesn't exist, then the default one is used instead.

## Miscellaneous

Volumes:

If you don't map any volume when using `docker run` or if you use `docker-compose` then Docker will create some internal volumes attached to your containers as follows.

-	Two volumes are created:
	-	A volume named `<prefix>_mysql-data` or `<prefix>_postgres-data` that contains the database data.
	-	A volume named `<prefix>_xwiki-data` that contains XWiki's permanent directory.
-	To find out where those volumes are located on your local host machine you can inspect them with `docker volume inspect <volume name>`. To find the volume name, you can list all volumes with `docker volume ls`.

-	Note that on Mac OSX, Docker runs inside the xhyve VM and thus the paths you get when inspecting the volumes are relative to this. Thus, you need to get into that VM if you need to access the volume data.

MySQL:

-	To issue some mysql commands:
	-	Find the container id with `docker ps`
	-	Execute bash in the mysql container: `docker exec -it <containerid> bash -l`
	-	Once inside the mysql container execute the `mysql` command: `mysql --user=xwiki --password=xwiki`

# For Maintainers

## Update Docker Images

- Create a JIRA issue on the [XDOCKER project](https://jira.xwiki.org/browse/XDOCKER) with subject `Upgrade stable version to <version>`.
- Update the version of XWiki in the `build.gradle` file found in the XWiki Docker repository (clone it locally first).
- To know how to generate the sha256, check the doc inside `build.gradle`. You need to download in advance the XWiki WAR file and run the according command in order to generate.
	- On Linux, use the following one-liner and replace the value of the `VERSION` variable accordingly:

		```console
		VERSION="12.10.10"; wget http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/${VERSION}/xwiki-platform-distribution-war-${VERSION}.war && sha256sum xwiki-platform-distribution-war-${VERSION}.war && rm xwiki-platform-distribution-war-${VERSION}.war
		```

	- On Mac, use the following one-liner and replace the value of the `VERSION` variable accordingly:

		```console
		VERSION="12.10.10"; wget http://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/${VERSION}/xwiki-platform-distribution-war-${VERSION}.war && shasum --algorithm 256 xwiki-platform-distribution-war-${VERSION}.war && rm xwiki-platform-distribution-war-${VERSION}.war
		```

- Execute the Gradle build (run `./gradlew`) to generate the various Dockerfiles and other resources for all image tags
- [Test](#testing-docker-images) the docker container
- If all is ok commit, push and close the jira issue created above
- Note down the SHA1 of the last commit and [update the official library file](https://github.com/docker-library/official-images/blob/master/library/xwiki) with it by creating a Pull Request (you can edit directly on the GitHub web page and create a Pull Request).
	- Important: Make sure to also add the `.0` version when releasing the first minor version for a given major. For example when releasing version `12.3`, also add the `12.3.0` tag so that users can refer to this exact version. Otherwise, when releasing `12.3.1`, the meaning of the `12.3` tag will change and will now mean `12.3.1`.
- Make sure to update this file if the documentation needs to be updated.

## Testing Docker Images

Test the modified files. On Linux, you need to use `sudo` on each docker command or configure it differently.

- First time only: Install Docker. For Mac you can use the Docker for Mac installer.
	- Make sure you open Docker before running the commands.
		- Linux (except Ubuntu): `sudo systemctl start docker`
- Create a network: `docker network create -d bridge xwiki-test`
- Execute the following command to start a Postgres database (for example):
  
	```console
    docker run --net=xwiki-test --name postgres-xwiki-test -v /tmp/xwiki-docker-test/postgres:/var/lib/postgresql/data -e POSTGRES_ROOT_PASSWORD=xwiki -e POSTGRES_USER=xwiki -e POSTGRES_PASSWORD=xwiki -e POSTGRES_DB=xwiki -e POSTGRES_INITDB_ARGS="--encoding=UTF8" -d postgres:latest
	```
	
- Navigate to the directory to test, e.g. `14/postgres-tomcat` and issue:
	- Build the image: `docker build -t xwiki-test .`
	- Start XWiki (using the started Postgres container in this example): 
  
		```console 
		docker run --net=xwiki-test --name xwiki-test -p 8080:8080 -v /tmp/xwiki-docker-test/xwiki:/usr/local/xwiki -e DB_USER=xwiki -e DB_PASSWORD=xwiki -e DB_DATABASE=xwiki -e DB_HOST=postgres-xwiki-test xwiki-test
		```
	
  	Note that same as for the Postgres container above you'll need to remove the container if it already exists.
  	
	- In case you had an XWiki instance running on 8080 and the above command fails (i.e. address already in use), you cannot simply run it again. If you do (and you should try, actually), will try to recreate the container with the `xwiki-test` name that is now already in use by a container for which you are given the ID (note that down). Instead, you need to simply start the mentioned container ID which previously failed by running `docker start <FAILED_START_CONTAINER_ID>`.
	- Open your browser to http://localhost:8080 and try to setup XWiki and verify it works
- If all is ok commit, push and close the JIRA issue created above

### Clean Up

Execute:

```console
docker stop xwiki-test
docker rm xwiki-test
docker stop postgres-xwiki-test
docker rm postgres-xwiki-test
docker network rm xwiki-test
docker rmi xwiki-test
sudo rm -Rf /tmp/xwiki-docker-test
```

# License

XWiki is licensed under the [LGPL 2.1](https://github.com/xwiki-contrib/docker-xwiki/blob/master/LICENSE).

The Dockerfile repository is also licensed under the [LGPL 2.1](https://github.com/xwiki-contrib/docker-xwiki/blob/master/LICENSE).

# Support

-	If you wish to raise an issue or an idea of improvement use [XWiki Docker JIRA project](https://jira.xwiki.org/browse/XDOCKER)
-	If you have questions, use the [XWiki Users Mailing List/Forum](https://dev.xwiki.org/xwiki/bin/view/Community/MailingLists) or use the [XWiki IRC channel](https://dev.xwiki.org/xwiki/bin/view/Community/IRC)

# Contribute

-	If you wish to help out on the code, please send Pull Requests on [XWiki Docker GitHub project](https://github.com/xwiki-contrib/docker-xwiki)
-	Note that changes need to be merged to all other branches where they make sense and if they make sense for existing tags, those tags must be deleted and recreated.
-	In addition, whenever a branch or tag is modified, a Pull Request on the [DockerHub XWiki official image](https://github.com/docker-library/official-images/blob/master/library/xwiki) must be made 

# Credits

-	Originally created by Vincent Massol
-	Contributions from Fabio Mancinelli, Ludovic Dubost, Jean Simard, Denis Germain and a lot of others
-	Some code was copied from https://github.com/ThomasSteinbach/docker_xwiki. Thank you Thomas Steinbach
-	Stolen XWiki ascii art from [https://github.com/babelop](babelop), see https://hub.docker.com/r/binarybabel/xwiki/~/dockerfile/
