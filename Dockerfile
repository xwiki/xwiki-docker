FROM debian:jessie-backports

MAINTAINER Fabio Mancinelli fabio.mancinelli@xwiki.com

# Set the mount points
VOLUME ["/var/lib/mysql", "/var/lib/xwiki"]

# Install JDK + MySQL + Tomcat7 + XWiki
RUN ( \
     apt-get update && \
     apt-get install -y openjdk-8-jdk && \
     apt-get install -y tomcat7 && \
     apt-get install -y libreoffice && \
     echo "mysql-server mysql-server/root_password password your_password" | /usr/bin/debconf-set-selections && \
     echo "mysql-server mysql-server/root_password_again password your_password" | /usr/bin/debconf-set-selections && \
     apt-get install -y mysql-server wget unzip git vim && \
     apt-get install -y coreutils sysvinit-utils procps sendxmpp bsd-mailx curl net-tools && \
     wget -P /tmp http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-8.4.1.war && \
     unzip -d /var/lib/tomcat7/webapps/xwiki /tmp/xwiki-enterprise-web-8.4.1.war && \
     wget -P /var/lib/tomcat7/webapps/xwiki/WEB-INF/lib http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.35/mysql-connector-java-5.1.35.jar && \
     mkdir -p /var/lib/xwiki && \
     git clone https://github.com/xwiki-contrib/xinit.git && \
     cd xinit && \
     ./install.sh --install && \
     chown -R tomcat7:tomcat7 /var/lib/xwiki && \
     sed "s/<id>org.xwiki.enterprise:xwiki-enterprise-web/<id>org.xwiki.enterprise:xwiki-enterprise-docker/" < /var/lib/tomcat7/webapps/xwiki/META-INF/extension.xed > /var/lib/tomcat7/webapps/xwiki/META-INF/extension2.xed && \
     mv /var/lib/tomcat7/webapps/xwiki/META-INF/extension2.xed /var/lib/tomcat7/webapps/xwiki/META-INF/extension.xed && \
     apt-get clean)

# Inject configuration files
ADD ["files/hibernate.cfg.xml", "files/xwiki.properties", "/var/lib/tomcat7/webapps/xwiki/WEB-INF/"]
ADD ["files/xinit.cfg", "/etc/xinit/"]
ADD ["files/index.html", "/var/lib/tomcat7/webapps/ROOT/"]
ADD ["files/start_xwiki.sh", "/"]

# Define the startup command
CMD ["/start_xwiki.sh"]

# Expose port
EXPOSE 8080

