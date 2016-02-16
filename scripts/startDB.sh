#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "start ${node_type} BEGIN"

systemctl start postgresql.service

ctx logger info "start ${node_type} COMPLETED"
