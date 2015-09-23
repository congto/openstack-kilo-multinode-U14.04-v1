#!/bin/bash -ex
#

source config.cfg

#
iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost
127.0.0.1       cinder 
$CON_MGNT_IP    controller
$COM1_MGNT_IP   compute1
$COM2_MGNT_IP	  compute2
$NET_MGNT_IP    network
$CIN_MGNT_IP    cinder
$SWIFT1_MGNT_IP swift1
$SWIFT2_MGNT_IP swift2

EOF

# Install CINDER 

apt-get -y install qemu lvm2 cinder-volume python-mysqldb

pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb


sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/vdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf


echo "########## Configuring for cinder.conf ##########"

filecinder=/etc/cinder/cinder.conf
test -f $filecinder.orig || cp $filecinder $filecinder.orig
rm $filecinder
cat << EOF > $filecinder
[DEFAULT]
rpc_backend = rabbit
my_ip = $CON_MGNT_IP

enabled_backends = lvm

glance_host = $CON_MGNT_IP

rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes


[database]
connection = mysql://cinder:$CINDER_DBPASS@$CON_MGNT_IP/cinder

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS


[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = tgtadm
 
[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = cinder
password = $CINDER_PASS

[oslo_concurrency]
lock_path = /var/lock/cinder

EOF

sleep 5
echo "Restart Cinder Volume" 
service tgt restart
service cinder-volume restart
rm -f /var/lib/cinder/cinder.sqlite

#### KET THUC CAI DAT CINDER 