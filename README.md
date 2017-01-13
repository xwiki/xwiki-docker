To use:

* Install Docker on your machine
* Install Git and run `git clone https://github.com/xwiki-contrib/docker-xwiki.git` or download the content of https://github.com/xwiki-contrib/docker-xwiki
* `docker-compose up`

Details:

* A volume named `dockerxwiki_mysql-data` is created. You can inspect it with `docker volume inspect dockerxwiki_mysql-data` and find out the location on your host's file system.
* To issue some mysql commands:
** Find the container id with `docker ps` 
** Execute bash in the mysql container: `docker exec -it <containerid> bash -l`
** Once inside the mysql container execute the `mysql` command: `mysql --user=xwiki --password=xwiki`

Future ideas:
* Setup xinit
* Configure libreoffice
* Solr as external service
