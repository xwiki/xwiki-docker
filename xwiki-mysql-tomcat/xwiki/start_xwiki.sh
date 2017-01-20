#!/bin/bash

function first_start() {
  configure
  sudo -u tomcat8 touch /var/lib/tomcat8/.first_start_completed
}

function configure() {
  echo 'Configuring XWiki...'
  sudo -u tomcat8 sed -i "s/replacemysqluser/${MYSQL_USERNAME:-xwiki}/g" /var/lib/tomcat8/webapps/ROOT/WEB-INF/hibernate.cfg.xml
  sudo -u tomcat8 sed -i "s/replacemysqlpassword/${MYSQL_PASSWORD:-xwiki}/g" /var/lib/tomcat8/webapps/ROOT/WEB-INF/hibernate.cfg.xml

  echo '  Using filesystem-based attachments...'
  xwiki-set-cfg 'xwiki.store.attachment.hint' 'file'
  xwiki-set-cfg 'xwiki.store.attachment.versioning.hint' 'file'
  xwiki-set-cfg 'xwiki.store.attachment.recyclebin.hint' 'file'
  echo '  Generating authentication validation and encryption keys...'
  xwiki-set-cfg 'xwiki.authentication.validationKey' "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
  xwiki-set-cfg 'xwiki.authentication.encryptionKey' "$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"

  echo '  Setting permanent directory...'
  xwiki-set-properties 'environment.permanentDirectory' '/var/lib/xwiki/data'
  echo '  Configure libreoffice...'
  xwiki-set-properties 'openoffice.autoStart' 'true'
}

if [[ ! -f /var/lib/tomcat/.first_start_completed ]]; then
  first_start
fi

sudo -u tomcat8 /usr/share/tomcat8/bin/catalina.sh run