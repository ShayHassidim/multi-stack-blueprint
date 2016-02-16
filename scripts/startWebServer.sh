#!/bin/bash

set -e

export CLOUDIFY_WS_NAME=tomcat

node_type=$(ctx node type)

ctx logger info "start ${node_type} BEGIN"

sudo systemctl start "$CLOUDIFY_WS_NAME.service"

ctx logger info "start ${node_type} COMPLETED"
