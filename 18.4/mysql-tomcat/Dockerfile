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
FROM tomcat:11-jre21

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

# Install the command-line tools and the native libraries required at runtime. LibreOffice itself is not installed here
# (see the dedicated step below) but the libraries it dynamically links to (and which its deb packages don't declare)
# are installed here so that they come from the base image's Debian release.
# Note that procps is required to get ps which is used by JODConverter to start LibreOffice.
# Note that libxinerama1, libdbus-glib-1-2, libcairo2, libcups2, libsm6, libx11-xcb1, libnss3, libxml2 and libxslt1.1
# are runtime dependencies of LibreOffice that are not pulled in transitively by its deb packages (this is the same set
# used by the XWiki Docker-based test framework that installs LibreOffice the same way).
# Note that libxtst6 and libxi6 are needed by the JDK's non-headless AWT backend (libawt_xawt.so), which the JVM loads
# when java.awt.headless is false, e.g. to let Java parse images (Tika/ImageIO indexing attachments in Solr). That
# library hard-links libXtst.so.6 and libXi.so.6, and with --no-install-recommends they are not pulled in transitively,
# so loading it fails with "libXtst.so.6: cannot open shared object file" (UnsatisfiedLinkError), cascading into
# "NoClassDefFoundError: Could not initialize class javax.imageio.ImageIO". In a container java.awt.headless defaults to
# true (no DISPLAY is set), so by default the JVM uses the headless backend (libawt_headless.so, no X11 deps) and the
# problem does not appear; installing these libraries keeps image parsing working when a user forces non-headless mode
# via -Djava.awt.headless=false or by setting a DISPLAY variable.
RUN apt-get update && \
  apt-get --no-install-recommends -y install \
    curl \
    unzip \
    procps \
    libxtst6 \
    libxi6 \
    libxinerama1 \
    libdbus-glib-1-2 \
    libcairo2 \
    libcups2 \
    libsm6 \
    libx11-xcb1 \
    libnss3 \
    libxml2 \
    libxslt1.1 && \
  rm -rf /var/lib/apt/lists/*

# Install a controlled version of LibreOffice (the one XWiki supports and tests against, i.e. the LTS version) instead
# of the version shipped by the base image's Debian release, so that it doesn't drift from the tested version. We take
# it from the Document Foundation download site (the same source and version used by the XWiki Docker-based test
# framework) and verify its sha256. Since the official image is built for both amd64 and arm64, we select the download
# matching the target architecture (provided automatically by Docker's TARGETARCH build argument) and its sha256. We
# install into /opt and symlink /opt/libreoffice, which is one of the paths XWiki (through JODConverter) probes to
# locate the LibreOffice installation automatically, so no extra configuration is needed.
ARG TARGETARCH
ENV LIBREOFFICE_VERSION="25.8.7"
ENV LIBREOFFICE_SHA256_AMD64="7f4d7b2e36921eec5122c655249a24cc88935ee357e8261fd3bccd15aa1f7b9f"
ENV LIBREOFFICE_SHA256_ARM64="67e9b7dcdeae72c7aa1357345307e67376fc2b729a7f9ebfafb372b010e22ffa"
ENV LIBREOFFICE_URL_PREFIX="https://download.documentfoundation.org/libreoffice/stable/${LIBREOFFICE_VERSION}/deb"
RUN case "$TARGETARCH" in \
    amd64) LO_ARCH_DIR=x86_64; LO_ARCH_FILE=x86-64; LO_SHA256=$LIBREOFFICE_SHA256_AMD64 ;; \
    arm64) LO_ARCH_DIR=aarch64; LO_ARCH_FILE=aarch64; LO_SHA256=$LIBREOFFICE_SHA256_ARM64 ;; \
    *) echo "Unsupported target architecture [$TARGETARCH] for the LibreOffice installation" >&2; exit 1 ;; \
  esac && \
  LO_ARCHIVE="LibreOffice_${LIBREOFFICE_VERSION}_Linux_${LO_ARCH_FILE}_deb.tar.gz" && \
  curl -fSL "${LIBREOFFICE_URL_PREFIX}/${LO_ARCH_DIR}/${LO_ARCHIVE}" -o /tmp/libreoffice.tar.gz && \
  echo "$LO_SHA256 /tmp/libreoffice.tar.gz" | sha256sum -c - && \
  mkdir -p /tmp/libreoffice && \
  tar -C /tmp/libreoffice -xf /tmp/libreoffice.tar.gz && \
  dpkg -i /tmp/libreoffice/LibreOffice_${LIBREOFFICE_VERSION}*_Linux_*_deb/DEBS/*.deb && \
  ln -fs $(ls -d /opt/libreoffice*) /opt/libreoffice && \
  rm -rf /tmp/libreoffice /tmp/libreoffice.tar.gz

# Install XWiki as the ROOT webapp context in Tomcat
# Create the Tomcat temporary directory
# Configure the XWiki permanent directory
ENV XWIKI_VERSION="18.4.2"
ENV XWIKI_URL_PREFIX "https://maven.xwiki.org/releases/org/xwiki/platform/xwiki-platform-distribution-war/${XWIKI_VERSION}"
ENV XWIKI_DOWNLOAD_SHA256 79c8149d26271f6271379bfc449a42bf51d745ca74984c4a1ee89cc4f9d1f399
RUN rm -rf /usr/local/tomcat/webapps/* && \
  mkdir -p /usr/local/tomcat/temp && \
  mkdir -p /usr/local/xwiki/data && \
  curl -fSL "${XWIKI_URL_PREFIX}/xwiki-platform-distribution-war-${XWIKI_VERSION}.war" -o xwiki.war && \
  echo "$XWIKI_DOWNLOAD_SHA256 xwiki.war" | sha256sum -c - && \
  unzip -d /usr/local/tomcat/webapps/ROOT xwiki.war && \
  rm -f xwiki.war

# Copy the JDBC driver in the XWiki webapp
# We take the database driver version from the Maven Central repository since we want to control the version 
# used and have it being consistent with what is tested in the CI.
ENV MYSQL_JDBC_VERSION="9.7.0"
ENV MYSQL_JDBC_SHA256="0353648eaa1c91e0f4020c959abf756bc866ffd583df22ae6b6f6e0cbd43eb44"
ENV MYSQL_JDBC_PREFIX="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/${MYSQL_JDBC_VERSION}"
ENV MYSQL_JDBC_ARTIFACT="mysql-connector-j-${MYSQL_JDBC_VERSION}.jar"
ENV MYSQL_JDBC_TARGET="/usr/local/tomcat/webapps/ROOT/WEB-INF/lib/${MYSQL_JDBC_ARTIFACT}"
RUN curl -fSL "${MYSQL_JDBC_PREFIX}/${MYSQL_JDBC_ARTIFACT}" -o $MYSQL_JDBC_TARGET && \
  echo "$MYSQL_JDBC_SHA256 $MYSQL_JDBC_TARGET" | sha256sum -c -

# Configure Tomcat. For example set the memory for the Tomcat JVM since the default value is too small for XWiki
COPY tomcat/setenv.sh /usr/local/tomcat/bin/

# Setup the XWiki Hibernate configuration
COPY xwiki/hibernate.cfg.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml

# Augment the XWiki WAR's own logback configuration with a rolling file appender so that logs are written both to the
# console (for "docker logs") and to a rotating file in the permanent directory, where they persist across container
# recreations. We patch the WAR's own file (rather than shipping a full copy of it) so that we don't drift from the
# version-specific logger levels it defines: the appender definition is inserted right after the opening
# <configuration> tag and its reference right after the existing "stdout" one.
COPY xwiki/logback-filelog-appender.xml xwiki/logback-filelog-ref.xml /tmp/
RUN LOGBACK=/usr/local/tomcat/webapps/ROOT/WEB-INF/classes/logback.xml && \
  sed -e '/<configuration/r /tmp/logback-filelog-appender.xml' \
      -e '/ref="stdout"/r /tmp/logback-filelog-ref.xml' \
      "$LOGBACK" > "$LOGBACK.new" && \
  mv "$LOGBACK.new" "$LOGBACK" && \
  rm -f /tmp/logback-filelog-appender.xml /tmp/logback-filelog-ref.xml

# Set a specific distribution id in XWiki for this docker packaging.
RUN sed -i 's/<id>org.xwiki.platform:xwiki-platform-distribution-war</<id>org.xwiki.platform:xwiki-platform-distribution-docker</' \
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
# - JDBC_PARAMS: Replaces the default JDBC parameters with the passed ones.

# Example:
#   docker run -it -e "DB_USER=xwiki" -e "DB_PASSWORD=xwiki" <imagename>

# Starts XWiki by starting Tomcat. All options passed to "docker run [OPTIONS] IMAGE[:TAG|@DIGEST] [COMMAND] [ARG...]"
# are also passed to docker-entrypoint.sh. If "xwiki" is passed then XWiki will be configured the first time the
# container executes and Tomcat will be started. If some other parameter is passed then it'll be executed to comply
# with best practices defined at https://github.com/docker-library/official-images#consistency.
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["xwiki"]
