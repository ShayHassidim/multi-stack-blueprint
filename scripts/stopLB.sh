#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "start ${node_type} BEGIN"

. ./nameLB.sh

systemctl stop "$CLOUDIFY_LB_NAME.service"

ctx logger info "start ${node_type} COMPLETED"

