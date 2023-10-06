#!/bin/bash

# Install docker
apt update
apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
apt update && apt -y install docker-ce docker-compose
usermod -aG docker ubuntu

# Run the guacamole container
mkdir /home/ubuntu/guacamole
cat << EOF > /home/ubuntu/guacamole/docker-compose.yaml
---
services:
  guacamole:
    image: guacamole/guacamole
    container_name: guacamole
    ports:
      - 8080:8080
    depends_on:
      - guacd
    networks:
      - guac-net
    env_file: guacamole-vars.env
    restart: always

  guacd:
    image: guacamole/guacd
    container_name: guacd
    networks:
      - guac-net
    restart: always

networks:
  guac-net:
    driver: bridge
EOF

cat << EOF > /home/ubuntu/guacamole/guacamole-vars.env
GUACD_HOSTNAME=guacd
MYSQL_HOSTNAME=<%DBHOST%>
MYSQL_DATABASE=guacamole_db
MYSQL_USER=guacamole_user
MYSQL_PASSWORD=<%DBPASSWORD%>
MYSQL_AUTO_CREATE_ACCOUNTS=true
LDAP_HOSTNAME=<%LDAP_HOST%>
LDAP_PORT=636
LDAP_ENCRYPTION_METHOD=ssl
LDAP_USER_BASE_DN=<%LDAP_USER_BASE%>
LDAP_GROUP_BASE_DN=<%LDAP_GROUP_BASE%>
LDAP_GROUP_SEARCH_FILTER=<%LDAP_GROUP_SEARCH_FILTER%>
LDAP_MEMBER_ATTRIBUTE=<%LDAP_MEMBER_ATTRIBUTE%>
LDAP_MEMBER_ATTRIBUTE_TYPE=<%LDAP_MEMBER_ATTRIBUTE_TYPE%>
LDAP_USER_ATTRIBUTES=<%LDAP_USER_ATTRIBUTES%>
LDAP_DEREFERENCE_ALIASES=always
LDAP_FOLLOW_REFERRALS='true'
REMOTE_IP_VALVE_ENABLED='true'
PROXY_ALLOWED_IPS_REGEX=<%RPROXY%>
EXTENSION_PRIORITY=ldap,mysql
EOF

chown -R ubuntu:ubuntu /home/ubuntu/guacamole
cd /home/ubuntu/guacamole; sudo -u ubuntu docker-compose up -d

# Munin plugins
wget https://raw.githubusercontent.com/munin-monitoring/contrib/master/plugins/docker/docker_ -O /usr/share/munin/plugins/docker_
chmod +x /usr/share/munin/plugins/docker_
ln -s /usr/share/munin/plugins/docker_ /etc/munin/plugins/docker_multi

cat << EOF > /etc/munin/plugin-conf.d/docker
[docker_*]
  user root
EOF
