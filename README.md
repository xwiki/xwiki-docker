Provides a full XWiki environment made up of the following:
* A container running the latest MySQL 5.x database and configured to use UTF8 and be case-insensitive
* A container running the latest Tomcat 8 + Java 8 + XWiki 8.4.4

All source files are under the LGPL 2.1 license.

Usage
-----

* Install Docker on your machine
* Install Git and run `git clone https://github.com/xwiki-contrib/docker-xwiki.git` or download the content of https://github.com/xwiki-contrib/docker-xwiki
* Go to the `xwiki-mysql-tomcat` directory: `cd xwiki-mysql-tomcat`
* Run `docker-compose up`

Details
-------

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

Future
------

* Setup xinit
* Configure libreoffice
* Solr as external service
