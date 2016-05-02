FROM debian:stable

MAINTAINER Vincent Massol <vincent@massol.net>

# Update
RUN apt-get update
RUN apt-get -y upgrade

# Install Java8
#RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
#  echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
#  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886 && \
#  apt-get update && \
#  apt-get -y --force-yes install oracle-java8-installer 

# Install Tomcat + LibreOffice + other tools
RUN apt-get -y --force-yes install wget unzip tomcat8 curl libreoffice

# Install XWiki as the ROOT webapp context in Tomcat
RUN rm -rf /var/lib/tomcat8/webapps/* && \
  curl -L 'http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-7.4.3.war' -o xwiki.war && \ 
  unzip -d /var/lib/tomcat8/webapps/ROOT xwiki.war && \
  rm -f xwiki.war

# Download the MySQL JDBC driver and install it in the XWiki webapp
RUN curl -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz -o mysql-connector-java-5.1.38.tar.gz && \
  tar xvf mysql-connector-java-5.1.38.tar.gz mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar -O > \
    /var/lib/tomcat8/webapps/ROOT/WEB-INF/lib/mysql-connector-java-5.1.38-bin.jar && \
  rm -f mysql-connector-java-5.1.38.tar.gz

# Configure the memory for the Tomcat JVM. Default value is too small for XWiki
COPY setenv.sh /usr/share/tomcat8/bin/

# Setup the XWiki Hibernate configuration
COPY hibernate.cfg.xml /var/lib/tomcat8/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# Configure the XWiki permanent directory
RUN mkdir -p /var/lib/xwiki 
COPY xwiki.properties /var/lib/tomcat8/webapps/ROOT/WEB-INF/xwiki.properties

# Set ownership and permission to the tomcat8 user
RUN chown -R tomcat8:tomcat8 /var/lib/xwiki /var/lib/tomcat8

# Start Tomcat with the tomcat8 user (created by apt-get tomcat8)
CMD /etc/init.d/tomcat8 start && read -p "Press a key to continue..."
