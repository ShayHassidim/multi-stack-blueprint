#!/bin/bash

set -e

node_type=$(ctx node type)

ctx logger info "configure ${node_type} BEGIN"

PGINSTALLDIR=/var/lib/pgsql/data
PGSQLCONF=postgresql.conf
PGHBACONF=pg_hba.conf
DBMASTER=10.0.0.30
LOCALHOST=127.0.0.1
DBSTANDBY=10.0.0.35
DBPORT=5432
DBUSER=postgres
REPUSER=dekker
REPPASS=replicant
MASTER_ARCHIVE=/export/database/archive
STANDBY_ARCHIVE=/export/database/archive
ARCHIVE_GROUP_ID=609
ARCHIVE_GROUP=archive

ctx logger info "PGINSTALLDIR:$PGINSTALLDIR"
ctx logger info "PGSQLCONF:$PGSQLCONF"
ctx logger info "PGHBACONF:$PGHBACONF"
ctx logger info "DBMASTER:$DBMASTER"
ctx logger info "LOCALHOST:$LOCALHOST"
ctx logger info "DBSTANDBY:$DBSTANDBY"
ctx logger info "DBPORT:$DBPORT"
ctx logger info "DBUSER:$DBUSER"
ctx logger info "REPUSER:$REPUSER"
ctx logger info "MASTER_ARCHIVE:$MASTER_ARCHIVE"

ctx logger info "ARCHIVE_GROUP_ID:$ARCHIVE_GROUP_ID"
ctx logger info "ARCHIVE_GROUP:$ARCHIVE_GROUP"

### postgres section ###

# install postgres
ctx logger info "installing postgresql"
yum -q -y install postgresql
ctx logger info "installing postgresql server"
yum -q -y install postgresql-server

# create the system database
ctx logger info "creating database"
postgresql-setup initdb

# enable the database services
ctx logger info "enabling postgres"
systemctl enable postgresql

# add note local parameters
ctx logger info "setting local parameters"
su - $DBUSER -c "echo \# local parameters >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo listen_addresses = \'$LOCALHOST,$DBMASTER\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo password_encryption = \'on\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo \# replication configuration >> $PGINSTALLDIR/$PGSQLCONF" 
su - $DBUSER -c "echo archive_mode = \'on\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo wal_level = \'hot_standby\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo max_wal_senders = \'4\' >> $PGINSTALLDIR/$PGSQLCONF"
su - $DBUSER -c "echo archive_command = \'cp -i %p $MASTER_ARCHIVE/%f\' >> $PGINSTALLDIR/$PGSQLCONF"

# set authorization/access
echo "setting local access"
su - $DBUSER -c "echo \# replication user access >> $PGINSTALLDIR/$PGHBACONF"
su - $DBUSER -c "echo host    replication    $REPUSER             $DBSTANDBY/32       trust >> $PGINSTALLDIR/$PGHBACONF"
su - $DBUSER -c "echo host    all            $REPUSER             $DBSTANDBY/32       md5 >> $PGINSTALLDIR/$PGHBACONF"
su - $DBUSER -c "echo host    replication    $REPUSER             $DBMASTER/32        trust >> $PGINSTALLDIR/$PGHBACONF"
su - $DBUSER -c "echo host    all            $REPUSER             $DBMASTER/32        md5 >> $PGINSTALLDIR/$PGHBACONF"

## nfs mount section ###

ctx logger info "installing nfs"
yum install -q -y nfs-utils

# create directory 
ctx logger info "creating nfs mount point"
mkdir -p $MASTER_ARCHIVE

# create group with specific id
ctx logger info "creating archive group"
groupadd -g $ARCHIVE_GROUP_ID $ARCHIVE_GROUP

# add ourselves to group
ctx logger info "adding $DBUSER to $ARCHIVE_GROUP"
usermod -a -G $ARCHIVE_GROUP $DBUSER

# set appropriate permissions 
ctx logger info "setting onwership and permissions on $MASTER_ARCHIVE"
chown -R root:$ARCHIVE_GROUP $MASTER_ARCHIVE && chmod -R g+rwx $MASTER_ARCHIVE

# modify /etc/fstab
ctx logger info "modifying fstab"
echo  "$DBSTANDBY:$STANDBY_ARCHIVE $MASTER_ARCHIVE nfs defaults,vers=3 0 0" >> /etc/fstab

# disable or pinhole firewalld
ctx logger info "disabling fiewall"
systemctl stop firewalld
systemctl disable firewalld

# wait here until the mount point exists
ctx logger info "waiting for shared directory"
MOUNTED=0
while [ "$MOUNTED" == "0" ]; do
    SHOWMOUNT=`showmount -e --no-headers 10.0.0.35`
	FOLDER=${SHOWMOUNT%\ *}
	if [ "$FOLDER" == "$STANDBY_ARCHIVE" ]; then
		MOUNTED=1
	else 
		sleep 5s
	fi
done

# mount the archive share
ctx logger info "mounting shared directory"
mount $MASTER_ARCHIVE

# start postgres
ctx logger info "starting postgres"
systemctl start postgresql

# create replication user and configure access
ctx logger info "creating replication user"
su - $DBUSER -c "createuser --login --replication $REPUSER"

ctx logger info "setting replication user password"
su - $DBUSER -c "psql -c \"alter user $REPUSER with password '$REPPASS';\""

ctx logger info "configure ${node_type} COMPLETED"
