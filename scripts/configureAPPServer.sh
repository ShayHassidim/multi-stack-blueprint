#!/bin/bash
  
set -e

node_type=$(ctx node type)

FILE=jboss-as-7.1.1.Final.zip
if [ ! -f "$FILE" ]
then
    ctx logger info  "File $FILE does not exists - downloading..."
	curl -O http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip
    ctx logger info  "done downloading..."
	sudo yum -y install unzip
	sudo unzip jboss-as-7.1.1.Final.zip	
    ctx logger info  "done installing jboss"
else
   ctx logger info  "jboss already installed"
fi

ctx logger info "configure ${node_type} done" 

