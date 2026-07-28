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
  # The marker lives in the webapp directory, which is not writable when the container runs with a read-only root
  # filesystem. Don't make the start fail in that case: configure() is idempotent, so the only consequence is that it
  # runs again on every start. Warn about it so that this isn't silent.
  if ! touch /usr/local/tomcat/webapps/$CONTEXT_PATH/.first_start_completed; then
    echo >&2 "  WARNING: Could not create the .first_start_completed marker in" \
      "/usr/local/tomcat/webapps/$CONTEXT_PATH. XWiki will be reconfigured on every container start."
  fi
}

function other_starts() {
  restoreConfigurationFile 'hibernate.cfg.xml'
  restoreConfigurationFile 'xwiki.cfg'
  restoreConfigurationFile 'xwiki.properties'
}

# We point java.io.tmpdir to a directory on the mapped permanent volume (see tomcat/setenv.sh) so that libraries
# writing there (e.g. the embedded Solr suggester) don't fill a small or tmpfs-backed default temp location
# (see XDOCKER-321). Since that directory lives on the volume and nothing in the container reaps temporary files, we
# empty it on every start to prevent it from growing without bound. This runs before Tomcat starts, so nothing is
# using it yet, and it mirrors what XWiki's own Environment does for its temporary directory.
function clean_temporary_directory() {
  rm -rf /usr/local/xwiki/data/tmp
  mkdir -p /usr/local/xwiki/data/tmp
}

# $1 - the path to xwiki.[cfg|properties]
# $2 - the setting/property to set
# $3 - the new value
function xwiki_replace() {
  # Read from a temporary copy and write the result back with a truncating redirect, instead of using "sed -i". Two
  # constraints are at play:
  # * "sed -i" creates a temporary file and performs a rename, thus changing the inode of the initial file, which makes
  #   it fail if you map the initial file as a Docker volume mount. The redirect truncates in place and preserves the
  #   inode.
  # * The temporary copy must not be created next to the target file, because the directory holding it is not writable
  #   when the container runs with a read-only root filesystem. It goes to the temporary directory on the permanent
  #   volume, which is writable and emptied on every start (see clean_temporary_directory).
  local file rc=0
  file="$(mktemp /usr/local/xwiki/data/tmp/"$(basename "$1")".XXXXXX)"
  cp "$1" "${file}"
  sed s~"\#\? \?$2 \?=.*"~"$2=$3"~g "${file}" > "$1" || rc=$?
  # When the redirect succeeded but sed failed, the target has been truncated and must be restored from the untouched
  # copy: for a bind-mounted configuration file, that target is the user's own file on the host. The "-w" test tells
  # that case apart from a redirect that never opened the target, where there is nothing to restore.
  if [ "$rc" -ne 0 ] && [ -w "$1" ]; then
    cp "${file}" "$1"
  fi
  rm -f "${file}"
  return "$rc"
}

# $1 - the setting/property to set
# $2 - the new value
function xwiki_set_cfg() {
  xwiki_replace /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/xwiki.cfg "$1" "$2"
}

# $1 - the setting/property to set
# $2 - the new value
function xwiki_set_properties() {
  xwiki_replace /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/xwiki.properties "$1" "$2"
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

# Allows to use sed but with user input which can contain special sed characters such as \, / or &.
# $1 - the text to search for
# $2 - the replacement text
# $3 - the file in which to do the search/replace
function safesed {
  # Same scheme as xwiki_replace: read from a temporary copy located on the permanent volume (the directory holding the
  # target file is not writable with a read-only root filesystem) and write the result back with a truncating redirect
  # so that the target file keeps its inode and file-level Docker volume mounts keep working.
  local file expression rc=0
  expression="s/$(echo $1 | sed -e 's/\([[\/.*]\|\]\)/\\&/g')/$(echo $2 | sed -e 's/[\/&]/\\&/g')/g"
  file="$(mktemp /usr/local/xwiki/data/tmp/"$(basename "$3")".XXXXXX)"
  cp "$3" "${file}"
  sed "${expression}" "${file}" > "$3" || rc=$?
  # Restore the truncated target from the untouched copy, for the same reason and with the same "-w" test as in
  # xwiki_replace.
  if [ "$rc" -ne 0 ] && [ -w "$3" ]; then
    cp "${file}" "$3"
  fi
  rm -f "${file}"
  return "$rc"
}

# $1 - the config file name found in WEB-INF (e.g. "xwiki.cfg")
function saveConfigurationFile() {
  if [ -f "/usr/local/xwiki/data/$1" ]; then
     echo "  Reusing existing config file $1..."
     cp "/usr/local/xwiki/data/$1" "/usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/$1"
  fi
}

# $1 - the config file name to restore in WEB-INF (e.g. "xwiki.cfg")
function restoreConfigurationFile() {
  if [ -f "/usr/local/xwiki/data/$1" ]; then
     echo "  Synchronizing config file $1..."
     cp "/usr/local/xwiki/data/$1" "/usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/$1"
  fi
}

function configure() {
  echo 'Configuring XWiki...'

  echo 'Setting environment variables'
  file_env 'DB_USER' 'xwiki'
  file_env 'DB_PASSWORD' 'xwiki'
  file_env 'DB_HOST' 'db'
  file_env 'DB_PORT' ''
  file_env 'DB_DATABASE' 'xwiki'
  file_env 'SOLR_BASE_URL' ''
  file_env 'JDBC_PARAMS' '?useSSL=false&amp;connectionTimeZone=LOCAL&amp;allowPublicKeyRetrieval=true'

  echo "  Deploying XWiki in the '$CONTEXT_PATH' context"
  if [ "$CONTEXT_PATH" == "ROOT" ]; then
    xwiki_set_cfg 'xwiki.webapppath' ''
  else
    mkdir -p -v /usr/local/tomcat/webapps/$CONTEXT_PATH
    cp -a --update=none /usr/local/tomcat/webapps/ROOT/.  /usr/local/tomcat/webapps/$CONTEXT_PATH/
  fi

  # When DB_PORT is set, it's added to the host in the JDBC URL of hibernate.cfg.xml, so that a DB listening on a
  # port other than the driver's default (3306) can be used.
  DB_HOST_AND_PORT="$DB_HOST"
  if [ -n "$DB_PORT" ]; then
    DB_HOST_AND_PORT="$DB_HOST:$DB_PORT"
  fi

  echo 'Replacing environment variables in files'
  safesed "replaceuser" $DB_USER /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/hibernate.cfg.xml
  safesed "replacepassword" $DB_PASSWORD /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/hibernate.cfg.xml
  safesed "replacecontainer" $DB_HOST_AND_PORT /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/hibernate.cfg.xml
  safesed "replacedatabase" $DB_DATABASE /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/hibernate.cfg.xml
  safesed "replacejdbcparams" $JDBC_PARAMS /usr/local/tomcat/webapps/$CONTEXT_PATH/WEB-INF/hibernate.cfg.xml

  # Set any non-default main wiki database name in the xwiki.cfg file.
  if [ "$DB_DATABASE" != "xwiki" ]; then
    xwiki_set_cfg "xwiki.db" $DB_DATABASE
  fi

  echo '  Setting permanent directory...'
  xwiki_set_properties 'environment.permanentDirectory' '/usr/local/xwiki/data'
  echo '  Configure libreoffice...'
  xwiki_set_properties 'openoffice.autoStart' 'true'

  # Configure a remote Solr instance when SOLR_BASE_URL is set (empty by default, meaning the embedded Solr is
  # used). SOLR_BASE_URL holds the full Solr base URL, so it can carry the scheme (e.g. https), a custom path and
  # the port.
  if [ -n "$SOLR_BASE_URL" ]; then
    echo '  Configuring remote Solr Index'
    xwiki_set_properties 'solr.type' 'remote'
    # Point to the Solr base URL (not a single core): XWiki manages several cores (search, events, ratings,
    # extension index) and creates its clients under this base. The old single-core "solr.remote.url" property is
    # deprecated and only configures the search core, which breaks the other cores.
    xwiki_set_properties 'solr.remote.baseURL' "$SOLR_BASE_URL"
  fi

  # If the files already exist then copy them to the XWiki's WEB-INF directory.
  saveConfigurationFile 'hibernate.cfg.xml'
  saveConfigurationFile 'xwiki.cfg'
  saveConfigurationFile 'xwiki.properties'
}

# This if will check if the first argument is a flag but only works if all arguments require a hyphenated flag
# -v; -SL; -f arg; etc will work, but not arg1 arg2
if [ "${1:0:1}" = '-' ]; then
    set -- xwiki "$@"
fi

# Check for the expected command
if [ "$1" = 'xwiki' ]; then
  file_env 'CONTEXT_PATH' 'ROOT'
  clean_temporary_directory
  # Ensure the logs directory exists on the (possibly freshly-mapped) permanent volume so that the logback file appender
  # configured in WEB-INF/classes/logback.xml can write to it right away.
  mkdir -p /usr/local/xwiki/data/logs
  if [[ ! -f /usr/local/tomcat/webapps/$CONTEXT_PATH/.first_start_completed ]]; then
    first_start
  else
    other_starts
  fi
  shift
  set -- catalina.sh run "$@"
fi

# Else default to run whatever the user wanted like "bash"
exec "$@"
