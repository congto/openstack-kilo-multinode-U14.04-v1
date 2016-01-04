#!/bin/bash -ex

### Script nay dung de cai cinder-api va cinder-scheduler tren node Controller
### cinder-volume cai tren cac node khac

source config.cfg


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
echo "########## Install CINDER ##########"
sleep 3
# apt-get install -y cinder-api cinder-scheduler cinder-volume iscsitarget open-iscsi iscsitarget-dkms python-cinderclient
apt-get install -y cinder-api cinder-scheduler python-cinderclient

echo "########## Configuring for cinder.conf ##########"

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

#Khai bao cho Ceilometer
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

# sed  -r -e 's#(filter = )(\[ "a/\.\*/" \])#\1[ "a\/sda1\/", "a\/sdb\/", "r/\.\*\/"]#g' /etc/lvm/lvm.conf

# Grant permission for cinder
chown cinder:cinder $filecinder

echo "########## Syncing Cinder DB ##########"
sleep 3
su -s /bin/sh -c "cinder-manage db sync" cinder
 
echo "########## Restarting CINDER service ##########"
sleep 3
service cinder-api restart
service cinder-scheduler restart
# service cinder-volume restart

rm -f /var/lib/cinder/cinder.sqlite

echo "########## Finish setting up CINDER !!! ##########"
