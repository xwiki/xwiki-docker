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

# \$1 - the path to xwiki.[cfg|properties]
# \$2 - the setting/property to set
# \$3 - the new value
function xwiki_replace() {
  sed -i s~"\\#\\? \\?\$2 \\?=.*"~"\$2=\$3"~g "\$1"
}

# \$1 - the setting/property to set
# \$2 - the new value
function xwiki_set_cfg() {
  xwiki_replace /usr/local/tomcat/webapps/ROOT/WEB-INF/xwiki.cfg "\$1" "\$2"
}

# \$1 - the setting/property to set
# \$2 - the new value
function xwiki_set_properties() {
  xwiki_replace /usr/local/tomcat/webapps/ROOT/WEB-INF/xwiki.properties "\$1" "\$2"
}

function configure() {
  echo 'Configuring XWiki...'
  sed -i "s/replaceuser/\${DB_USER:-xwiki}/g" /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml
  sed -i "s/replacepassword/\${DB_PASSWORD:-xwiki}/g" /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml
  sed -i "s/replacecontainer/\${DB_HOST:-db}/g" /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml
  sed -i "s/replacedatabase/\${DB_DATABASE:-xwiki}/g" /usr/local/tomcat/webapps/ROOT/WEB-INF/hibernate.cfg.xml

  echo '  Using filesystem-based attachments...'
  xwiki_set_cfg 'xwiki.store.attachment.hint' 'file'
  xwiki_set_cfg 'xwiki.store.attachment.versioning.hint' 'file'
  xwiki_set_cfg 'xwiki.store.attachment.recyclebin.hint' 'file'
  echo '  Generating authentication validation and encryption keys...'
  xwiki_set_cfg 'xwiki.authentication.validationKey' "\$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
  xwiki_set_cfg 'xwiki.authentication.encryptionKey' "\$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

  echo '  Setting permanent directory...'
  xwiki_set_properties 'environment.permanentDirectory' '/usr/local/xwiki/data'
  echo '  Configure libreoffice...'
  xwiki_set_properties 'openoffice.autoStart' 'true'
}

# This if will check if the first argument is a flag but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "\${1:0:1}" = '-' ]; then
    set -- xwiki "\$@"
fi

# Check for the expected command
if [ "\$1" = 'xwiki' ]; then
  if [[ ! -f /usr/local/xwiki/.first_start_completed ]]; then
    first_start
  fi
  shift
  set -- catalina.sh run "\$@"
fi

# Else default to run whatever the user wanted like "bash"
exec "\$@"
