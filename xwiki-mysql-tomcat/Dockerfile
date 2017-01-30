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
FROM tomcat:8-jre8

MAINTAINER Vincent Massol <vincent@massol.net>

# Note: when using docker-compose, the ENV values below are overridden from the .env file.

# Install LibreOffice + other tools
RUN apt-get update && \
  apt-get -y upgrade && \
  apt-get --no-install-recommends -y --force-yes install \
    curl \
    libreoffice \
    unzip && \
  rm -rf /var/lib/apt/lists/*

# Install XWiki as the ROOT webapp context in Tomcat
# Create the Tomcat temporary directory
# Configure the XWiki permanent directory
ENV XWIKI_VERSION=8.4.4
RUN rm -rf /usr/local/tomcat/webapps/* && \
  mkdir -p /usr/local/tomcat/temp && \
  mkdir -p /usr/local/xwiki/data && \
  curl -L "http://download.forge.ow2.org/xwiki/xwiki-enterprise-web-${XWIKI_VERSION}.war" -o xwiki.war && \ 
  unzip -d /usr/local/tomcat/webapps/ROOT xwiki.war && \
  rm -f xwiki.war

# Download the MySQL JDBC driver and install it in the XWiki webapp
ENV MYSQL_DRIVER_VERSION=5.1.38
RUN curl -L https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz \
    -o mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
  tar xvf mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz \
    mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar -O > \
    /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar && \
  rm -f mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz

# Configure Tomcat. For example set the memory for the Tomcat JVM since the default value is too small for XWiki
COPY tomcat/setenv.sh /usr/local/tomcat/bin/

# Setup the XWiki Hibernate configuration
ENV MYSQL_DATABASE=xwiki
COPY xwiki/hibernate.cfg.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# Set a specific distribution id in XWiki for this docker packaging.
RUN sed "s/<id>org.xwiki.enterprise:xwiki-enterprise-web/<id>org.xwiki.enterprise:xwiki-enterprise-docker/" \
    < /usr/local/tomcat/webapps/ROOT/META-INF/extension.xed > /usr/local/tomcat/webapps/ROOT/META-INF/extension2.xed && \
  mv /usr/local/tomcat/webapps/ROOT/META-INF/extension2.xed /usr/local/tomcat/webapps/ROOT/META-INF/extension.xed

# Add scripts required to make changes to XWiki configuration files at execution time
# Note: we don't run CHMOD since 1) it's not required since the executabe bit is already set in git and 2) running
# CHMOD after a COPY will sometimes fail, depending on different host-specific factors (especially on AUFS).
COPY xwiki/xwiki-config-replace.sh /usr/local/bin/xwiki-config-replace.sh
COPY xwiki/xwiki-set-cfg /usr/local/bin/xwiki-set-cfg
COPY xwiki/xwiki-set-properties /usr/local/bin/xwiki-set-properties
COPY xwiki/start_xwiki.sh /usr/local/bin/start_xwiki.sh

# Make the XWiki directory (the permanent directory is included in it) persist on the host (so that it's not recreated
# across runs)
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
ENV MYSQL_USER=xwiki \
    MYSQL_PASSWORD=xwiki
ENTRYPOINT ["start_xwiki.sh"]

# When no options are passed on the "docker run" command line we display a message explaining what environment
# variables can be overridden.
# Note: This is not implemented yet and FTM --info does nothing.
CMD ["--info"]
