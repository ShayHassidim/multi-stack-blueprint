#!/bin/bash

set -e

export CLOUDIFY_LB_NAME=httpd
export LB_IP_ADDR=10.8.1.88

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

. ./nameLB.sh

CLOUDIFY_LB_NAME_INSTALLED=`rpm -qa | grep $CLOUDIFY_LB_NAME`

if [ -z "$CLOUDIFY_LB_NAME_INSTALLED" ] ; then
		ctx logger info "configure ${node_type} ${CLOUDIFY_LB_NAME} already installed"
		exit 2
fi

CLOUDIFY_NGINX_INSTALLED=`rpm -qa | grep nginx`

if [ -z "$CLOUDIFY_NGINX_INSTALLED" ] ; then
	systemctl stop nginx
	systemctl disable nginx
fi

export HTTPD_CONF="/etc/httpd/conf/httpd.conf"

yum -q -y install "$CLOUDIFY_LB_NAME"

sed -i 's/ServerName\ www\.example\.com\:80/ServerName\ www\.example\.com\:80\nServerName\ '"$LB_IP_ADDR"':80/' $HTTPD_CONF

ctx logger info "configure ${node_type} COMPLETED"
