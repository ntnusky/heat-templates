#!/bin/bash

# Variables
FQDN='<%GUACAMOLE_FQDN%>'
ADMIN_EMAIL='<%ADMIN_EMAIL%>'
GUACAMOLE_HOST='<%GUACAMOLE_HOST%>'
TLS_KEY='<%TLS_KEY%>'
TLS_CERT='<%TLS_CERT%>'
CERT_CHAIN='<%CERT_CHAIN%>'
IPV4=$(hostname -I | cut -d' ' -f1)
IPV6=$(hostname -I | cut -d' ' -f2)

# Write certs
cat << EOF > /etc/ssl/private/${FQDN}.key
$(echo -n "${TLS_KEY}" | base64 -d)
EOF

cat << EOF > /etc/ssl/certs/${FQDN}.pem
$(echo -n "${TLS_CERT}" | base64 -d)
EOF

cat << EOF > /etc/ssl/certs/cert-chain.pem
$(echo -n "${CERT_CHAIN}" | base64 -d)
EOF

chmod 0600 /etc/ssl/private/${FQDN}.key

# Construct rewrite pattern for HTTP_HOST
HTTP_HOST_PATTERN=$(echo ${FQDN} | sed 's|\.|\\.|g')

# Install and configure apache2
apt update
apt -y install apache2 liblwp-protocol-https-perl
a2enmod proxy proxy_wstunnel proxy_http proxy_http2 rewrite ssl headers
a2dissite 000-default

cat << EOF > /etc/apache2/sites-available/${FQDN}.conf
<IfModule mpm_event_module>
  ServerLimit 128
  MaxRequestWorkers 3200
</IfModule>
<VirtualHost *:80>
	ServerName $FQDN
	ServerAdmin $ADMIN_EMAIL

	Redirect "/" "https://${FQDN}/"

	RewriteEngine on
	RewriteCond %{SERVER_NAME} =${FQDN}
	RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>
<IfModule mod_ssl.c>
<VirtualHost *:443>
	ServerName $FQDN

  RewriteEngine on
  RewriteCond %{HTTP_HOST} ${HTTP_HOST_PATTERN} [NC]
  RewriteCond %{REQUEST_URI} ^/$
  RewriteRule ^(.*)$ https://${FQDN}/guacamole/ [L,R=301]

	SetEnvIf Request_URI "^/guacamole/tunnel" dontlog"
	LogFormat "%h %l %u %t \"%r\" %<s %b" common
	ErrorLog /var/log/apache2/${FQDN}_error.log
	CustomLog /var/log/apache2/${FQDN}_access.log common env=!dontlog

	Protocols h2 http/1.1

	SSLEngine on
  Include /etc/apache2/conf-available/ntnu-ssl.conf
	SSLCertificateFile /etc/ssl/certs/${FQDN}.pem
	SSLCertificateKeyFile /etc/ssl/private/${FQDN}.key
	SSLCertificateChainFile /etc/ssl/certs/cert-chain.pem

	<Location /guacamole/>
		Require all granted
		ProxyPass http://${GUACAMOLE_HOST}:8080/guacamole/ flushpackets=on
		ProxyPassReverse http://${GUACAMOLE_HOST}:8080/guacamole/
	</Location>
	<Location /guacamole/websocket-tunnel>
		Require all granted
		ProxyPass ws://${GUACAMOLE_HOST}:8080/guacamole/websocket-tunnel
		ProxyPassReverse ws://${GUACAMOLE_HOST}:8080/guacamole/websocket-tunnel
	</Location>

  <Location "/server-status">
    SetHandler server-status
    Satisfy any
    Require host localhost
    Require host ${IPV4}
    Require host ${IPV6}
  </Location>

</VirtualHost>
</IfModule>
EOF

cat << EOF > /etc/apache2/conf-available/ntnu-ssl.conf
# Baseline setting to Include for SSL sites
# Dette er stjålet fra letsencrypt sin baseline. Fjerna HSTS

SSLEngine on

# Intermediate configuration, tweak to your needs
SSLProtocol             all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1 -TLSv1.2

SSLCipherSuite          ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256

SSLHonorCipherOrder     on
SSLCompression          off
SSLSessionTickets       off

SSLOptions +StrictRequire

# Add vhost name to log entries:
LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" vhost_combined
LogFormat "%v %h %l %u %t \"%r\" %>s %b" vhost_common

CustomLog /var/log/apache2/access.log vhost_combined
LogLevel warn
ErrorLog /var/log/apache2/error.log

# Always ensure Cookies have "Secure" set (JAH 2012/1)
Header edit Set-Cookie (?i)^(.*)(;\s*secure)??((\s*;)?(.*)) "\$1; Secure\$3\$4"
EOF

a2ensite ${FQDN}.conf
systemctl restart apache2

# Munin plugins
ln -s /usr/share/munin/plugins/apache_* /etc/munin/plugins/
cat << EOF > /etc/munin/plugin-conf.d/apache
[apache_*]
  env.url   https://${FQDN}:%d/server-status?auto
  env.ports 443

[http_loadtime]
   env.target https://${FQDN}/guacamole/#/
EOF
