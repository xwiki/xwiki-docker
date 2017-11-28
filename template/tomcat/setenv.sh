# We're making the following changes to the default:
# * Adding more memory (default is 512MB which is not enough for XWiki)
# * By default, Tomcat does not allow the usage of encoded slash '%2F' and backslash '%5C' in URLs, as noted in
#   http://tomcat.apache.org/security-6.html#Fixed_in_Apache_Tomcat_6.0.10. We want to allow for them as it's useful to
#   be able to have '/' and '\' in wiki page names.
# * On some system /dev/random is slow to init leading to a slow Tomcat and thus Xwiki startup.
export CATALINA_OPTS="-Xmx1024m -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true -Dsecurerandom.source=file:/dev/urandom"
