#!/bin/bash

set -e

node_type=$(ctx node type)

cd jboss-as-7.1.1.Final/bin
ctx logger info "about to start jboss..." 

sudo ./standalone.sh -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0&

ctx logger info "jboss started OK" 

ctx logger info "start ${node_type} " 

