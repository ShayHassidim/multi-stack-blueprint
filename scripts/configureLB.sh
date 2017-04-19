#!/bin/bash

set -e

export CLOUDIFY_LB_NAME=httpd
#export LB_HOST_IP=10.8.1.88

ctx logger info "configure ${node_type} on ${CLOUDIFY_LB_NAME} "

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

CLOUDIFY_LB_NAME_INSTALLED=`rpm -qa | grep $CLOUDIFY_LB_NAME`

if [ -z "$CLOUDIFY_LB_NAME_INSTALLED" ] ; then
		ctx logger info "configure ${node_type} ${CLOUDIFY_LB_NAME} already installed"
		exit 2
fi

CLOUDIFY_NGINX_INSTALLED=`rpm -qa | grep nginx`

if [ -z "$CLOUDIFY_NGINX_INSTALLED" ] ; then
	sudo systemctl stop nginx
	sudo systemctl disable nginx
fi

export HTTPD_CONF="/etc/httpd/conf/httpd.conf"

sudo yum -q -y install "$CLOUDIFY_LB_NAME"

sudo sed -i 's/ServerName\ www\.example\.com\:80/ServerName\ www\.example\.com\:80\nServerName\ '"$LB_HOST_IP"':80/' $HTTPD_CONF

ctx logger info "configure ${node_type} COMPLETED"
