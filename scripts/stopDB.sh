#!/bin/bash

node_type=$(ctx node type)

ctx logger info "stop ${node_type} BEGIN"

systemctl stop postgresql.service

ctx logger info "stop ${node_type} COMPLETED"
