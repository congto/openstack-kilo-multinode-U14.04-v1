#!/bin/bash -ex
### Script nay dung de cai tat ca thanh phan Cinder tren node Controller
source config.cfg

apt-get install lvm2 -y

echo "########## Tao Physical Volume va Volume Group (tren disk sdb ) ##########"
fdisk -l
pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb
sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/vdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf


## Create a cinder user, endpoint
openstack user create --password $ADMIN_PASS cinder
openstack role add --project service --user cinder admin
openstack service create --name cinder --description "OpenStack Block Storage" volume
openstack service create --name cinderv2  --description "OpenStack Block Storage" volumev2

openstack endpoint create \
--publicurl http://$CON_MGNT_IP:8776/v1/%\(tenant_id\)s \
--internalurl http://$CON_MGNT_IP:8776/v1/%\(tenant_id\)s \
--adminurl http://$CON_MGNT_IP:8776/v1/%\(tenant_id\)s \
--region RegionOne \
volume


openstack endpoint create \
--publicurl http://$CON_MGNT_IP:8776/v2/%\(tenant_id\)s \
--internalurl http://$CON_MGNT_IP:8776/v2/%\(tenant_id\)s \
--adminurl http://$CON_MGNT_IP:8776/v2/%\(tenant_id\)s \
--region RegionOne \
volumev2

#
echo "########## Cai dat cac goi cho CINDER ##########"
sleep 3
apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient


echo "########## Cau hinh file cho cinder.conf ##########"

filecinder=/etc/cinder/cinder.conf
test -f $filecinder.orig || cp $filecinder $filecinder.orig
rm $filecinder
cat << EOF > $filecinder
[DEFAULT]
rpc_backend = rabbit
my_ip = $CON_MGNT_IP

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

#Khai bao cho ceilomter
control_exchange = cinder
notification_driver = messagingv2

[database]
connection = mysql://cinder:$CINDER_DBPASS@$CON_MGNT_IP/cinder

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

 
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


# Phan quyen cho file cinder
chown cinder:cinder $filecinder

echo "########## Dong bo cho cinder ##########"
sleep 3
cinder-manage db sync

echo "########## Khoi dong lai CINDER ##########"
sleep 3
service cinder-api restart
service cinder-scheduler restart
service cinder-volume restart

echo "########## Hoan thanh viec cai dat CINDER ##########"

