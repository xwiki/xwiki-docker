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
FROM tomcat:9-jre11

#    ____  ____  ____      ____  _   __        _
#   |_  _||_  _||_  _|    |_  _|(_) [  |  _   (_)
#     \ \  / /    \ \  /\  / /  __   | | / ]  __
#      > `' <      \ \/  \/ /  [  |  | '' <  [  |
#    _/ /'`\ \_     \  /\  /    | |  | |`\ \  | |
#   |____||____|     \/  \/    [___][__|  \_][___]

LABEL org.opencontainers.image.authors='XWiki Development Team <committers@xwiki.org>'
LABEL org.opencontainers.image.url='https://hub.docker.com/_/xwiki'
LABEL org.opencontainers.image.documentation='https://hub.docker.com/_/xwiki'
LABEL org.opencontainers.image.source='https://github.com/xwiki/xwiki-docker.git'
LABEL org.opencontainers.image.vendor='xwiki.org'
LABEL org.opencontainers.image.licenses='LGPL-2.1'

# Note: when using docker-compose, the ENV values below are overridden from the .env file.

# Install LibreOffice + other tools
# Note that procps is required to get ps which is used by JODConverter to start LibreOffice
RUN apt-get update && \
  apt-get --no-install-recommends -y install \
    curl \
    libreoffice \
    unzip \
    procps && \
  rm -rf /var/lib/apt/lists/*

# Install XWiki as the ROOT webapp context in Tomcat
# Create the Tomcat temporary directory
# Configure the XWiki permanent directory
ENV XWIKI_VERSION="14.4.7"
ENV XWIKI_URL_PREFIX "https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-distribution-war/${XWIKI_VERSION}"
ENV XWIKI_DOWNLOAD_SHA256 4545869f5e088c88401556f473edf356ff9e358652edd766d2588e8164ef68e0
RUN rm -rf /usr/local/tomcat/webapps/* && \
  mkdir -p /usr/local/tomcat/temp && \
  mkdir -p /usr/local/xwiki/data && \
  curl -fSL "${XWIKI_URL_PREFIX}/xwiki-platform-distribution-war-${XWIKI_VERSION}.war" -o xwiki.war && \
  echo "$XWIKI_DOWNLOAD_SHA256 xwiki.war" | sha256sum -c - && \
  unzip -d /usr/local/tomcat/webapps/ROOT xwiki.war && \
  rm -f xwiki.war

# Copy the JDBC driver in the XWiki webapp
# For MariaDB, download the MariaDB driver version from the Maven Central repository to control the version 
# used.
ENV MARIADB_JDBC_VERSION="3.1.0"
ENV MARIADB_JDBC_SHA256="bf78c92310a848b348f8478667f68fd17f8b80963c67474e8199f5abc8acbd50"
ENV MARIADB_JDBC_PREFIX="https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/${MARIADB_JDBC_VERSION}"
ENV MARIADB_JDBC_ARTIFACT="mariadb-java-client-${MARIADB_JDBC_VERSION}.jar"
ENV MARIADB_JDBC_TARGET="/usr/local/tomcat/webapps/ROOT/WEB-INF/lib/${MARIADB_JDBC_ARTIFACT}"
RUN curl -fSL "${MARIADB_JDBC_PREFIX}/${MARIADB_JDBC_ARTIFACT}" -o $MARIADB_JDBC_TARGET && \
  echo "$MARIADB_JDBC_SHA256 $MARIADB_JDBC_TARGET" | sha256sum -c -

# Configure Tomcat. For example set the memory for the Tomcat JVM since the default value is too small for XWiki
COPY tomcat/setenv.sh /usr/local/tomcat/bin/

# Setup the XWiki Hibernate configuration
COPY xwiki/hibernate.cfg.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# Set a specific distribution id in XWiki for this docker packaging.
RUN sed -i 's/<id>org.xwiki.platform:xwiki-platform-distribution-war/<id>org.xwiki.platform:xwiki-platform-distribution-docker/' \
  /usr/local/tomcat/webapps/ROOT/META-INF/extension.xed

# Add scripts required to make changes to XWiki configuration files at execution time
# Note: we don't run CHMOD since 1) it's not required since the executabe bit is already set in git and 2) running
# CHMOD after a COPY will sometimes fail, depending on different host-specific factors (especially on AUFS).
COPY xwiki/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Make the XWiki directory (the permanent directory is included in it) persist on the host (so that it's not recreated
# across runs)
VOLUME /usr/local/xwiki

# At this point the image is done and what remains below are the runtime configuration used by the user to configure
# the container that will be created out of the image. Namely the user can override some environment variables with
#   docker run -e "var1=val1" -e "var2=val2" ...
# The supported environment variables that can be overridden are:
# - DB_USER: the name of the user configured for XWiki in the DB. Default is "xwiki". This is used to configure
#            xwiki's hibernate.cfg.xml file.
# - DB_PASSWORD: the password for the user configured for XWiki in the DB. Default is "xwiki". This is used to
#                configure xwiki's hibernate.cfg.xml file.
# - DB_DATABASE: the name of the database to use. Default is "xwiki". This is used to configure xwiki's
#                hibernate.cfg.xml file.
# - DB_HOST: The name of the host (or docker container) containing the database. Default is "db". This is used to
#            configure xwiki's hibernate.cfg.xml file.
# - CONTEXT_PATH: The name of the context path under which XWiki will be deployed in Tomcat. If not specified then it'll
#                 be deployed as ROOT.

# Example:
#   docker run -it -e "DB_USER=xwiki" -e "DB_PASSWORD=xwiki" <imagename>

# Starts XWiki by starting Tomcat. All options passed to "docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [COMMAND] [ARG...]"
# are also passed to docker-entrypoint.sh. If "xwiki" is passed then XWiki will be configured the first time the
# container executes and Tomcat will be started. If some other parameter is passed then it'll be executed to comply
# with best practices defined at https://github.com/docker-library/official-images#consistency.
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["xwiki"]
