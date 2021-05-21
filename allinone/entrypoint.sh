#!/bin/bash

if [ "${DB_HOST}" == "127.0.0.1" ]; then
	if [[ ! -d "/var/lib/mysql/${DB_NAME}" ]]; then
		mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
		chown -R mysql:mysql "/var/log/mysql*"
		chmod -R 0775 "/var/log/mysql*"
		mysqld --daemonize --user=mysql
		if [[ ! -z $(pidof mysqld) ]]; then
			sleep 2
			mysql -uroot -e "create database 'jumpserver' default charset 'utf8' collate 'utf8_bin';"
			mysql -uroot -e "create user 'jumpserver'@'127.0.0.1' identified with mysql_native_password by '${DB_PASSWORD}';"
			mysql -uroot -e "grant all privileges on jumpserver.* to 'jumpserver'@'127.0.0.1'; flush privileges;"
		else
			echo "Mysql数据库未启动"
			sleep 5
		fi
	else
		chown -R mysql:mysql "/var/lib/mysql/${DB_NAME}"
		chmod -R 0775 "/var/log/mysql*"
		mysqld --daemonize --user=mysql
	fi
fi

if [ "$REDIS_HOST" == "127.0.0.1" ]; then
	redis-server &
fi

if [ ! -f "/opt/jumpserver/config.yml" ]; then
	echo >/opt/jumpserver/config.yml
fi

if [ ! "$WINDOWS_SKIP_ALL_MANUAL_PASSWORD" ]; then
	export WINDOWS_SKIP_ALL_MANUAL_PASSWORD=True
fi

source /opt/py3/bin/activate
cd /opt/jumpserver && ./jms start -d
cd /opt/koko && ./koko -d
/etc/init.d/guacd start
sh /config/tomcat10/bin/startup.sh
/usr/sbin/nginx &

# shellcheck disable=SC2154
echo "Jumpserver ALL ${Version}"
tail -f /var/log/nginx/access.log
