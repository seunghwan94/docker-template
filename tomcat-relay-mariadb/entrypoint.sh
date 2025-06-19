#!/usr/bin/env bash
set -e

# 1) 루트 비밀번호 설정 (.env)
echo "root:${ROOT_PASSWORD}" | chpasswd

# 2) 키스토어 생성 (최초 1회)
KS_FILE="$CATALINA_HOME/conf/keystore.jks"
if [ ! -f "$KS_FILE" ]; then
  keytool -genkeypair \
    -alias     "$KEYSTORE_ALIAS" \
    -keyalg    RSA \
    -keystore  "$KS_FILE" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass   "$KEYSTORE_PASSWORD" \
    -dname     "$KEYSTORE_DNAME"
fi

# 3) HTTPS 커넥터 삽입 (최초 1회)
if ! grep -q "certificateKeystoreFile" "$CATALINA_HOME/conf/server.xml"; then
  sed -i '/<\/Service>/i \
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol" SSLEnabled="true">\
  <SSLHostConfig>\
    <Certificate certificateKeystoreFile="'"$KS_FILE"'" certificateKeystorePassword="'"$KEYSTORE_PASSWORD"'" />\
  </SSLHostConfig>\
</Connector>' "$CATALINA_HOME/conf/server.xml"
fi

# 4) SSH + Tomcat 실행
/usr/sbin/sshd
exec catalina.sh run
