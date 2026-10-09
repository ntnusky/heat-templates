#!/bin/bash

# Variables
FQDN='<%GUACAMOLE_FQDN%>'
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

cat << EOF >> /etc/ssl/certs/${FQDN}.pem
$(echo -n "${CERT_CHAIN}" | base64 -d)
EOF

chmod 0600 /etc/ssl/private/${FQDN}.key

# Install and configure nginx
apt update
apt -y install nginx

cat << EOF > /etc/nginx/sites-available/${FQDN}.conf
server {
  listen 443 ssl;
  listen [::]:443 ssl;
  http2 on;
  server_name ${FQDN};

  ssl_certificate /etc/ssl/certs/${FQDN}.pem;
  ssl_certificate_key /etc/ssl/private/${FQDN}.key;

  ssl_session_timeout 1d;
  ssl_session_cache shared:MozSSL:10m;

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ecdh_curve X25519:prime256v1:secp384r1;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
  ssl_prefer_server_ciphers off;

  resolver 129.241.0.200 129.241.0.201 [2001:700:300::200] [2001:700:300::201];

  access_log /var/log/nginx/${FQDN}_access.log;
  error_log /var/log/nginx/${FQDN}_error.log warn;

  location / {
    proxy_pass http://${GUACAMOLE_HOST}:8080/guacamole/;
    proxy_buffering off;
    proxy_http_version 1.1;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-Port \$server_port;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$http_connection;
  }
}
EOF

cat << EOF > /etc/nginx/sites-available/default-http-https-redirect
server {
  listen 80 default_server;
  server_name _;
  return 301 https://\$host\$request_uri;
}
EOF

cat << EOF > /etc/nginx/sites-available/status
server {
  listen 127.0.0.1:80;
  listen [::1]:80;

  server_name _;

  location = /basic_status {
    stub_status;
    allow ${IPV4};
    allow ${IPV6};
    allow 127.0.0.1;
    allow ::1;
    deny all;
  }
}
EOF

ln -s /etc/nginx/sites-available/${FQDN}.conf /etc/nginx/sites-enabled/${FQDN}.conf
ln -s /etc/nginx/sites-available/status /etc/nginx/sites-enabled/status
ln -s /etc/nginx/sites-available/default-http-https-redirect /etc/nginx/sites-enabled/default-http-https-redirect
rm /etc/nginx/sites-enabled/default
systemctl restart nginx
