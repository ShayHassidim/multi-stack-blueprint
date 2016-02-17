#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "start ${node_type} BEGIN"

sudo systemctl start postgresql.service

ctx logger info "start ${node_type} COMPLETED"
