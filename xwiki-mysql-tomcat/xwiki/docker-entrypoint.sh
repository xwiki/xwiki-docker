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

set -e

function first_start() {
  configure
  touch /usr/local/xwiki/.first_start_completed
}

function configure() {
  echo 'Configuring XWiki...'
  sed -i "s/replacemysqluser/${MYSQL_USERNAME:-xwiki}/g" /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml
  sed -i "s/replacemysqlpassword/${MYSQL_PASSWORD:-xwiki}/g" /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml

  echo '  Using filesystem-based attachments...'
  xwiki-set-cfg 'xwiki.store.attachment.hint' 'file'
  xwiki-set-cfg 'xwiki.store.attachment.versioning.hint' 'file'
  xwiki-set-cfg 'xwiki.store.attachment.recyclebin.hint' 'file'
  echo '  Generating authentication validation and encryption keys...'
  xwiki-set-cfg 'xwiki.authentication.validationKey' "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
  xwiki-set-cfg 'xwiki.authentication.encryptionKey' "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

  echo '  Setting permanent directory...'
  xwiki-set-properties 'environment.permanentDirectory' '/usr/local/xwiki/data'
  echo '  Configure libreoffice...'
  xwiki-set-properties 'openoffice.autoStart' 'true'
}

# This if will check if the first argument is a flag but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "${1:0:1}" = '-' ]; then
    set -- xwiki "$@"
fi

# Check for the expected command
if [ "$1" = 'xwiki' ]; then
  if [[ ! -f /usr/local/xwiki/.first_start_completed ]]; then
    first_start
  fi
  /usr/local/tomcat/bin/catalina.sh run
fi

# Else default to run whatever the user wanted like "bash"
exec "$@"
