#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

. ./nameWS.sh

CLOUDIFY_WS_NAME_INSTALLED=`rpm -qa | grep $CLOUDIFY_WS_NAME`

if [ -z "$CLOUDIFY_WS_NAME_INSTALLED" ] ; then
		ctx logger info "configure ${node_type} ${CLOUDIFY_WS_NAME} already installed"
        exit 2
fi

yum -q -y install "$CLOUDIFY_WS_NAME"

ctx logger info "configure ${node_type} COMPLETED"
