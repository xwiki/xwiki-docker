FROM debian:jessie-backports

MAINTAINER Fabio Mancinelli fabio.mancinelli@xwiki.com

# Set the mount points
VOLUME ["/var/lib/mysql", "/var/lib/xwiki"]

# Install JDK + MySQL + Tomcat7 + XWiki
RUN ( \
     apt-get update && \
     apt-get install -y openjdk-8-jdk && \
     apt-get install -y tomcat7 && \
     echo "mysql-server mysql-server/root_password password your_password" | /usr/bin/debconf-set-selections && \
     echo "mysql-server mysql-server/root_password_again password your_password" | /usr/bin/debconf-set-selections && \
     apt-get install -y mysql-server && \
     apt-get install -y wget && \
     apt-get install -y unzip && \
     wget -P /tmp http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-8.4.1.war && \
     unzip -d /var/lib/tomcat7/webapps/xwiki /tmp/xwiki-enterprise-web-8.4.1.war && \
     wget -P /var/lib/tomcat7/webapps/xwiki/WEB-INF/lib http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.35/mysql-connector-java-5.1.35.jar && \
     mkdir -p /var/lib/xwiki && \
     mkdir -p /var/tmp/xwiki && \
     chown tomcat7:tomcat7 /var/lib/xwiki && \
     mkdir -p /var/lib/tomcat7/bin && \
     chown tomcat7:tomcat7 /var/lib/tomcat7/bin && \
     apt-get clean)

# Inject configuration files
ADD ["files/hibernate.cfg.xml", "files/xwiki.properties", "/var/lib/tomcat7/webapps/xwiki/WEB-INF/"]
ADD ["files/start_xwiki.sh", "/"]

# Define the startup command
CMD ["/start_xwiki.sh"]

# Expose port
EXPOSE 8080

