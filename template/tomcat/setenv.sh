# By default, Tomcat does not allow the usage of encoded slash '%2F' and backslash '%5C' in URLs, as noted in http://tomcat.apache.org/security-6.html#Fixed_in_Apache_Tomcat_6.0.10.
# This is why we're passing 2 system properties to allow for them as it's useful to be able to have '/' and '\' in wiki pahe names.
export CATALINA_OPTS="-Xmx1024m -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true"
