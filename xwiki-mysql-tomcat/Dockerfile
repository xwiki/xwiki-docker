# ---------------------------------------------------------------------------
# See the NOTICE file distributed with this work for additional
# information regarding copyright ownership.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.
# ---------------------------------------------------------------------------
FROM debian:jessie

MAINTAINER Vincent Massol <vincent@massol.net>

# Note: when using docker-compose, these values are overridden from the .env file.
ENV XWIKI_VERSION=8.4.4 \
    MYSQL_DRIVER_VERSION=5.1.38 \
    MYSQL_USER=xwiki \
    MYSQL_PASSWORD=xwiki \
    MYSQL_DATABASE=xwiki

# Install Java8 + Tomcat + LibreOffice + other tools
RUN echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get -y --force-yes install \
    curl \
    libreoffice \
    nano \
    openjdk-8-jdk \
    sudo \
    tomcat8 \
    unzip

# Install XWiki as the ROOT webapp context in Tomcat
RUN rm -rf /var/lib/tomcat8/webapps/* && \
  curl -L "http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-${XWIKI_VERSION}.war" -o xwiki.war && \ 
  unzip -d /var/lib/tomcat8/webapps/ROOT xwiki.war && \
  rm -f xwiki.war

# Download the MySQL JDBC driver and install it in the XWiki webapp
RUN curl -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz \
    -o mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
  tar xvf mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz \
    mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar -O > \
    /var/lib/tomcat8/webapps/ROOT/WEB-INF/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar && \
  rm -f mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz

# Configure Tomcat. For example set the memory for the Tomcat JVM since the default value is too small for XWiki
COPY tomcat/setenv.sh /usr/share/tomcat8/bin/

# Create the Tomcat temporary directory
RUN mkdir -p /var/lib/tomcat8/temp

# Setup the XWiki Hibernate configuration
COPY xwiki/hibernate.cfg.xml /var/lib/tomcat8/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# Configure the XWiki permanent directory
RUN mkdir -p /var/lib/xwiki

# Set a specific distribution id in XWiki for this docker packaging.
RUN sed "s/<id>org.xwiki.enterprise:xwiki-enterprise-web/<id>org.xwiki.enterprise:xwiki-enterprise-docker/" \
    < /var/lib/tomcat8/webapps/ROOT/META-INF/extension.xed > /var/lib/tomcat8/webapps/ROOT/META-INF/extension2.xed && \
  mv /var/lib/tomcat8/webapps/ROOT/META-INF/extension2.xed /var/lib/tomcat8/webapps/ROOT/META-INF/extension.xed

# Set ownership and permission to the tomcat8 user
RUN chown -R tomcat8:tomcat8 /var/lib/xwiki
RUN chown -R tomcat8:tomcat8 /var/lib/tomcat8

# Add scripts required to make changes to XWiki configuration files at execution time
COPY xwiki/xwiki-config-replace.sh /usr/local/bin/xwiki-config-replace.sh
COPY xwiki/xwiki-set-cfg /usr/local/bin/xwiki-set-cfg
COPY xwiki/xwiki-set-properties /usr/local/bin/xwiki-set-properties
COPY xwiki/start_xwiki.sh /usr/local/bin/start_xwiki.sh
RUN chmod 0755 /usr/local/bin/xwiki-config-replace.sh /usr/local/bin/xwiki-set-cfg /usr/local/bin/xwiki-set-properties \
  /usr/local/bin/start_xwiki.sh

# Make the XWiki permanent directory persist on the host (so that it's not recreated across runs)
VOLUME /var/lib/xwiki

# Expose the Tomcat port
EXPOSE 8080

# At this point the image is done and what remains below are the runtime configuration used by the user to configure
# the container that will be created out of the image. Namely the user can override some environment variables with
#   docker run -e "var1=val1" -e "var2=val2" ...
# The supported environment variables that can be overridden are:
# - MYSQL_USER: the name of the user configured for XWiki in the DB. Default is "xwiki". This is used to configure
#               xwiki's hibernate.cfg.xml file.
# - MYSQL_PASSWORD: the password for the user configured for XWiki in the DB. Default is "xwiki". This is used to
#                   configure xwiki's hibernate.cfg.xml file.
# Example:
#   docker run -it -e "MYSQL_USER=xwiki" -e "MYSQL_PASSWORD=xwiki" <imagename>

# Starts XWiki by starting Tomcat. All options passed to "docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [COMMAND] [ARG...]"
# are also passed to start_xwiki.sh. However at the moment start_xwiki.sh doesn't support any parameters and all
# configurations are done through environment variable overrides (see above).
ENTRYPOINT ["start_xwiki.sh"]

# When no options are passed on the "docker run" command line we display a message explaining what environment
# variables can be overridden.
# Note: This is not implemented yet and FTM --info does nothing.
CMD ["--info"]
