#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "stop ${node_type} BEGIN"

sudo systemctl stop postgresql.service

ctx logger info "stop ${node_type} COMPLETED"
