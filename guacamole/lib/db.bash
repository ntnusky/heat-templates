#!/bin/bash

if mountpoint -q /var/lib/mysql; then
  rm -rf /var/lib/mysql/*
else
  mount /var/lib/mysql
  rm -rf /var/lib/mysql/*
fi

apt update

# Install and configure MySQL. The script block is the manual
# alternative to the mysql_secure_installation command
DEBIAN_FRONTEND=noninteractive apt -y install mysql-server pwgen libdbd-mysql-perl libcache-cache-perl
pw='<%DB_ROOT_PW%>'
guac_pw='<%DB_GUACAMOLE_PW%>'
ip=$(hostname -I | cut -d' ' -f1)
mysql -sfu root <<EOS
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$pw';
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOS

echo "MySQL root password: $pw" >> /home/ubuntu/install.log
echo "MySQL guacamole_user password: $guac_pw" >> /home/ubuntu/install.log

sed -i "s/127.0.0.1/$ip,127.0.0.1/g" /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql.service

# Creating what's needed for guacamole
mysql -sfu root -p${pw} <<EOS
CREATE DATABASE guacamole_db;
CREATE USER 'guacamole_user'@'<%GUAC_HOST%>' IDENTIFIED WITH mysql_native_password BY '$guac_pw';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacamole_db.* TO 'guacamole_user'@'<%GUAC_HOST%>';
FLUSH PRIVILEGES;
EOS

wget -q https://repo.it.ntnu.no/guacamole/initdb.sql -O /tmp/initdb.sql
mysql -u root -p${pw} guacamole_db < /tmp/initdb.sql
rm /tmp/initdb.sql

# Munin plugins
for i in $(/usr/share/munin/plugins/mysql_ suggest); do ln -s /usr/share/munin/plugins/mysql_ /etc/munin/plugins/mysql_$i; done
rm /etc/munin/plugins/mysql_replication /etc/munin/plugins/mysql_binlog_groupcommit /etc/munin/plugins/mysql_innodb_io_pend
cat << EOF > /etc/munin/plugin-conf.d/mysql
[mysql_*]
  env.mysqlpassword ${pw}
EOF
