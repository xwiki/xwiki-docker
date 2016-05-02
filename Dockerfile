FROM debian:jessie

MAINTAINER Vincent Massol <vincent@massol.net>

ENV XWIKI_VERSION=7.4.3 \
	MYSQL_DRIVER_VERSION=5.1.38

# Install Java8 + Tomcat + LibreOffice + other tools
RUN echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y --force-yes install sudo nano unzip curl openjdk-8-jdk tomcat8 libreoffice

# Install XWiki as the ROOT webapp context in Tomcat
RUN rm -rf /var/lib/tomcat8/webapps/* && \
  curl -L "http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-${XWIKI_VERSION}.war" -o xwiki.war && \ 
  unzip -d /var/lib/tomcat8/webapps/ROOT xwiki.war && \
  rm -f xwiki.war

# Download the MySQL JDBC driver and install it in the XWiki webapp
RUN curl -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz -o mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
  tar xvf mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar -O > \
    /var/lib/tomcat8/webapps/ROOT/WEB-INF/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar && \
  rm -f mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz

# Configure Tomcat. For example set the memory for the Tomcat JVM since the default value is too small for XWiki
COPY setenv.sh /usr/share/tomcat8/bin/

# Create the Tomcat temporary directory
RUN mkdir -p /var/lib/tomcat8/temp

# Setup the XWiki Hibernate configuration
COPY hibernate.cfg.xml /var/lib/tomcat8/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# Configure the XWiki permanent directory
RUN mkdir -p /var/lib/xwiki
COPY xwiki.properties /var/lib/tomcat8/webapps/ROOT/WEB-INF/xwiki.properties

# Make the XWiki permanent directory no be recreated across runs
VOLUME /var/lib/xwiki

# Set ownership and permission to the tomcat8 user
RUN chown -R tomcat8:tomcat8 /var/lib/xwiki /var/lib/tomcat8

# Start Tomcat with the tomcat8 user (created by apt-get tomcat8)
CMD sudo -u tomcat8 /usr/share/tomcat8/bin/catalina.sh run
