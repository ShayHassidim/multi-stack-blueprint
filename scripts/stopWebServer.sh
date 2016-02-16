#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "start ${node_type} BEGIN"

. ./nameWS.sh

systemctl stop "$CLOUDIFY_WS_NAME.service"

ctx logger info "start ${node_type} COMPLETED"
