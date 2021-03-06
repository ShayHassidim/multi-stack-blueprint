#!/bin/bash

set -e

export CLOUDIFY_LB_NAME=httpd

node_type=$(ctx node type)

ctx logger info "start ${node_type} BEGIN"

sudo systemctl start "$CLOUDIFY_LB_NAME.service"

ctx logger info "start ${node_type} COMPLETED"
