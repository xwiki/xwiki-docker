#!/bin/bash
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

# We're making the following changes to the default:
# * Adding more memory (default is 512MB which is not enough for XWiki)
# * By default, Tomcat does not allow the usage of encoded slash '%2F' and backslash '%5C' in URLs, as noted in
#   https://tomcat.apache.org/security-6.html#Fixed_in_Apache_Tomcat_6.0.10. We want to allow for them as it's useful to
#   be able to have '/' and '\' in wiki page names.
# * On some system /dev/random is slow to init leading to a slow Tomcat and thus Xwiki startup.
# * Pointing the temporary directory to a folder on the mapped permanent volume (see CATALINA_TMPDIR below). Solr (the
#   embedded suggester) and other libraries write temporary files directly to java.io.tmpdir, which is not configurable
#   at their level. The default location can be small or tmpfs-backed in a container, leading to "No space left on
#   device" errors even though the data volume has room (see XDOCKER-321). The directory is emptied on every start by
#   docker-entrypoint.sh so it cannot grow without bound.

# Users can override these values by setting the JAVA_OPTS environment variable. For example:
# -e JAVA_OPTS="-Xmx2048m"

XMX="-Xmx1024m"
ALLOW_ENCODED_SLASH="-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true"
ALLOW_BACKSLASH="-Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true"
SECURERANDOM="-Djava.security.egd=file:/dev/./urandom"

if [[ ! -z "\$JAVA_OPTS" ]]; then
  if [[ ! \$JAVA_OPTS =~ .*-Xmx[0-9]+.* ]]; then
    JAVA_OPTS="\$JAVA_OPTS \$XMX"
  fi
  if [[ ! \$JAVA_OPTS =~ .*ALLOW_ENCODED_SLASH.* ]]; then
    JAVA_OPTS="\$JAVA_OPTS \$ALLOW_ENCODED_SLASH"
  fi
  if [[ ! \$JAVA_OPTS =~ .*ALLOW_BACKSLASH.* ]]; then
    JAVA_OPTS="\$JAVA_OPTS \$ALLOW_BACKSLASH"
  fi
  if [[ ! \$JAVA_OPTS =~ .*java\\.security\\.egd.* ]]; then
    JAVA_OPTS="\$JAVA_OPTS \$SECURERANDOM"
  fi
else
  JAVA_OPTS="\$XMX \$ALLOW_ENCODED_SLASH \$ALLOW_BACKSLASH \$SECURERANDOM"
fi

export JAVA_OPTS

# Point the JVM temporary directory (java.io.tmpdir) to a folder on the mapped permanent volume. We set it through
# CATALINA_TMPDIR rather than JAVA_OPTS on purpose: catalina.sh appends "-Djava.io.tmpdir=\$CATALINA_TMPDIR" *after*
# JAVA_OPTS, so a java.io.tmpdir passed via JAVA_OPTS would be overridden. Since catalina.sh only defaults
# CATALINA_TMPDIR when it is empty, setting it here (unless the user already provided one) makes it win. The directory
# is emptied on every start by docker-entrypoint.sh. See XDOCKER-321.
if [[ -z "\$CATALINA_TMPDIR" ]]; then
  CATALINA_TMPDIR="/usr/local/xwiki/data/tmp"
fi
export CATALINA_TMPDIR
