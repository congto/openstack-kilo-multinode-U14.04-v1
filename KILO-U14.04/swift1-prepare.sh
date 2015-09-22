#!/bin/bash -ex

source config.cfg


iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost
127.0.0.1       swift1
$CON_MGNT_IP    controller
$COM1_MGNT_IP   compute1
$COM2_MGNT_IP	  compute2
$NET_MGNT_IP    network
$CIN_MGNT_IP    cinder
$SWIFT1_MGNT_IP swift1


EOF


apt-get install xfsprogs rsync -y
mkfs.xfs /dev/vdb
mkfs.xfs /dev/vdc

mkdir -p /srv/node/vdb
mkdir -p /srv/node/vdc

echo "/dev/vdb /srv/node/vdb xfs _netdev 0 0" >>  /etc/fstab
echo "/dev/vdc /srv/node/vdc xfs _netdev 0 0" >>  /etc/fstab
mount /dev/vdb /srv/node/vdb
mount /dev/vdc /srv/node/vdc

cat << EOF > /etc/rsyncd.conf

uid = swift
gid = swift
log file = /var/log/rsyncd.log
pid file = /var/run/rsyncd.pid
address = $SWIFT1_MGNT_IP
 
[account]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/account.lock
 
[container]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/container.lock
 
[object]
max connections = 2
path = /srv/node/
read only = false
lock file = /var/lock/object.lock

EOF

sed  -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g'  /etc/default/rsync
service rsync start
 

### Cai dat cac goi tren Swift1 node
apt-get -y install swift swift-account swift-container swift-object

cat << EOF > /etc/swift/account-server.conf
[DEFAULT]
bind_ip = $SWIFT1_MGNT_IP
bind_port = 6002
user = swift
swift_dir = /etc/swift
devices = /srv/node

[pipeline:main]
pipeline = healthcheck recon account-server
[app:account-server]
use = egg:swift#account
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift

[account-replicator]
[account-auditor]
[account-reaper]
[filter:xprofile]
use = egg:swift#xprofile

EOF

cat << EOF > /etc/swift/container-server.conf 
[DEFAULT]
bind_ip = $SWIFT1_MGNT_IP
bind_port = 6001
user = swift
swift_dir = /etc/swift
devices = /srv/node

[pipeline:main]
pipeline = healthcheck recon container-server
[app:container-server]
use = egg:swift#container
[filter:healthcheck]
use = egg:swift#healthcheck

[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift

[container-replicator]
[container-updater]
[container-auditor]
[container-sync]
[filter:xprofile]
use = egg:swift#xprofile
EOF


cat << EOF >  /etc/swift/object-server.conf

[DEFAULT]
bind_ip = $SWIFT1_MGNT_IP
bind_port = 6000
user = swift
swift_dir = /etc/swift
devices = /srv/node

[pipeline:main]
pipeline = healthcheck recon object-server
[app:object-server]
use = egg:swift#object
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:recon]
use = egg:swift#recon
recon_cache_path = /var/cache/swift
recon_lock_path = /var/lock

[object-replicator]
[object-reconstructor]
[object-updater]
[object-auditor]
[filter:xprofile]
use = egg:swift#xprofile
EOF

curl -o /etc/swift/container-reconciler.conf \
https://git.openstack.org/cgit/openstack/swift/plain/etc/container-reconciler.conf-sample?h=stable/kilo

curl -o /etc/swift/object-expirer.conf \
https://git.openstack.org/cgit/openstack/swift/plain/etc/object-expirer.conf-sample?h=stable/kilo

 cat << EOF >  /etc/swift/swift.conf
[swift-hash]
swift_hash_path_prefix = xrfuniounenqjnw
swift_hash_path_suffix = fLIbertYgibbitZ

[storage-policy:0]
name = Policy-0
default = yes
[swift-constraints]

EOF


chown -R swift:swift /srv/node
mkdir -p /var/cache/swift
chown -R swift:swift /var/cache/swift
 