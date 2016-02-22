#!/bin/bash

set -e
  
node_type=$(ctx node type)

cd jboss-as-7.1.1.Final/bin
sudo ./jboss-cli.sh --connect command=:shutdown

ctx logger info "stop ${node_type} " 

