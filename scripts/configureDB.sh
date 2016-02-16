#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

sudo yum -y install postgresql-server
sudo postgresql-setup initdb
sudo systemctl enable postgresql.service

ctx logger info "configure ${node_type} COMPLETED"
