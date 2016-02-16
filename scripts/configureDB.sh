#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

yum -y install postgresql-server
postgresql-setup initdb
systemctl enable postgresql.service

ctx logger info "configure ${node_type} COMPLETED"
