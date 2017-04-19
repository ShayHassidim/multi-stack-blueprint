#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

PGINSTALLDIR=/var/lib/pgsql/data
PGSQLCONF=postgresql.conf
PGRECCONF=recovery.conf
#DBMASTER=10.0.0.30
LOCALHOST=127.0.0.1
#DBSTANDBY=10.0.0.35
STANDBY_ARCHIVE=/export/database/archive
ARCHIVE_GROUP=archive
DBPORT=5432
DBUSER=postgres
REPUSER=dekker
REPPASS=replicant

ctx logger info "PGINSTALLDIR:$PGINSTALLDIR"
ctx logger info "PGRECCONF:$PGRECCONF"
ctx logger info "DBMASTER:$DBMASTER"
ctx logger info "LOCALHOST:$LOCALHOST"
ctx logger info "DBSTANDBY:$DBSTANDBY"
ctx logger info "STANDBY_ARCHIVE:$STANDBY_ARCHIVE"
ctx logger info "ARCHIVE_GROUP:$ARCHIVE_GROUP"
ctx logger info "DBPORT:$DBPORT"
ctx logger info "DBUSER:$DBUSER"
ctx logger info "REPUSER:$REPUSER"

# install nfs-kernel
ctx logger info "installing nfs"
yum -q -y install nfs-server

# create archive directory
mkdir -p $STANDBY_ARCHIVE
	
# create group with specific id
groupadd -g 609 $ARCHIVE_GROUP

# add ourselves to group
usermod -a -G $ARCHIVE_GROUP REPUSER

# set appropriate permissions
chown -R root:$ARCHIVE_GROUP $STANDBY_ARCHIVE && chmod -R g+wx $STANDBY_ARCHIVE

# add to exports 
ctx logger info "creating export"
echo "$STANDBY_ARCHIVE    $DB_MASTER_IP_ADDR/24(rw,sync)" >> /etc/exports

# restart nfs/portmap 
ctx logger info "restarting nfs"
systemctl stop nfs && systemctl enable nfs && systemctl start nfs

# install postgres
ctx logger info "installing postgresql"
yum -q -y install postgresql
ctx logger info "installing postgressql server"
yum -q -y install postgresql-server

# create the system database
ctx logger info "creating initial database"
postgresql-setup initdb

ctx logger info "enabling postgresql"
systemctl enable postgresql

ctx logger info "copying $PGSQLCONF to /tmp"
su - $DBUSER -c "cp $PGINSTALLDIR/$PGSQLCONF /tmp/$PGSQLCONF"

ctx logger info "removing files from $PGINSTALLDIR"
rm -rf $PGINSTALLDIR/*

# wait here until the share is mounted and then wait 5s more
ctx logger info "waiting mounted share"
SHARED=0
while [ "$SHARED" == "0" ]; do
    SHOWMOUNT=`showmount ---no-headers`
	if [ "$SHOWMOUONT" != "" ]; then
		SHARED=1
	fi
	sleep 5s
done

# create the original backup
ctx logger info "creating base backup"
su - $DBUSER -c "pg_basebackup -D $PGINSTALLDIR -h $DBMASTER -U $REPUSER -w -v --xlog-method=stream"

# configure the standby
ctx logger info "copying $PGSQLCONF back to $PGINSTALLDIR"
su - $DBUSER -c "cp /tmp/$PGSQLCONF $PGINSTALLDIR/$PGSQLCONF"

ctx logger info "setting local parameters"
su - $DBUSER -c "echo \# local parameters >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo listen_addresses = \'$LOCALHOST,$DBMASTER\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo password_encryption = \'on\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo \# standby parameters >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo hot_standby = \'on\'  >> $PGINSTALLDIR/$PGSQLCONF"

# create recovery.conf
ctx logger info "creating $PGRECCONF"
su - $DBUSER -c "echo standby_mode = \'on\' >> $PGINSTALLDIR/$PGRECCONF"
su - $DBUSER -c "echo primary_conninfo = \'host=$DBMASTER port=$DBPORT user=$REPUSER password=$DBPASS\' >> $PGINSTALLDIR/$PGRECCONF"
su - $DBUSER -c "echo restore_command = \'cp $STANDBY_ARCHIVE/%f %p\' >> $PGINSTALLDIR/$PGRECCONF"
su - $DBUSER -c "echo archive_cleanup_command = \'pg_archivecleanup $STANDBY_ARCHIVE %r\' >> $PGINSTALLDIR/$PGRECCONF"

# start the database
ctx logger info "starting postgresql"
systemctl start postgresql

ctx logger info "configure ${node_type} COMPLETED"
