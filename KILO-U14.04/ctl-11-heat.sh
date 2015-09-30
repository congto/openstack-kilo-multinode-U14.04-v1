#!/bin/bash -ex
#
source config.cfg

# database create
echo "Tao database Heat"
sleep 10

cat << EOF | mysql -uroot -p$MYSQL_PASS
DROP DATABASE IF EXISTS heat;
CREATE DATABASE heat;
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'localhost' \
  IDENTIFIED BY '$HEAT_DBPASS';
GRANT ALL PRIVILEGES ON heat.* TO 'heat'@'%' \
  IDENTIFIED BY '$HEAT_DBPASS';

EOF


# Keystone config
echo "Cau hinh keystone"
sleep 10

source admin-openrc.sh

openstack user create --password $HEAT_PASS heat

openstack role add --project service --user heat admin

openstack role create heat_stack_owner

openstack role add --project demo --user demo heat_stack_owner

openstack role create heat_stack_user

openstack service create --name heat --description "Orchestration" orchestration

openstack service create --name heat-cfn --description "Orchestration"  cloudformation

openstack endpoint create \
  --publicurl http://$CON_MGNT_IP:8004/v1/%\(tenant_id\)s \
  --internalurl http://$CON_MGNT_IP:8004/v1/%\(tenant_id\)s \
  --adminurl http://$CON_MGNT_IP:8004/v1/%\(tenant_id\)s \
  --region RegionOne \
  orchestration
  
openstack endpoint create \
  --publicurl http://$CON_MGNT_IP:8000/v1 \
  --internalurl http://$CON_MGNT_IP:8000/v1 \
  --adminurl http://$CON_MGNT_IP:8000/v1 \
  --region RegionOne \
  cloudformation
  

#Install all package
echo "Install all package"
apt-get install -y heat-api heat-api-cfn heat-engine python-heatclient


#Configure heat.conf
echo "Configure heat.conf "
heatconfig=/etc/heat/heat.conf
test -f $heatconfig.orig || cp $heatconfig $heatconfig.orig
rm $heatconfig
touch $heatconfig

cat << EOF >> $heatconfig

[DEFAULT]
verbose = True
rpc_backend = rabbit
heat_metadata_server_url = http://$CON_MGNT_IP:8000
heat_waitcondition_server_url = http://$CON_MGNT_IP:8000/v1/waitcondition
stack_domain_admin = heat_domain_admin
stack_domain_admin_password = $HEAT_PASS
stack_user_domain_name = heat_user_domain

[database]
connection = mysql://heat:$HEAT_DBPASS@$CON_MGNT_IP/heat

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000/v2.0
identity_uri = http://$CON_MGNT_IP:35357
admin_tenant_name = service
admin_user = heat
admin_password = $HEAT_PASS

[matchmaker_redis]

[matchmaker_ring]

[oslo_messaging_amqp]

[oslo_messaging_qpid]

[oslo_messaging_rabbit]
rabbit_host = controller
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[ec2authtoken]
auth_uri = http://$CON_MGNT_IP:5000/v2.0

EOF


heat-keystone-setup-domain \
  --stack-user-domain-name heat_user_domain \
  --stack-domain-admin heat_domain_admin \
  --stack-domain-admin-password $HEAT_PASS
  
echo "Create tables"
sleep 5
su -s /bin/sh -c "heat-manage db_sync" heat

echo "Restart all services"
sleep 10
service heat-api restart
service heat-api-cfn restart
service heat-engine restart

rm -f /var/lib/heat/heat.sqlite


#Testing Heat
echo "Create simple template"
sleep 5
mkdir heat-template
cd heat-template

cat << EOF >> test-stack.yml

heat_template_version: 2014-10-16
description: A simple server.
 
parameters:
  ImageID:
    type: string
    description: Image use to boot a server
  NetID:
    type: string
    description: Network ID for the server
 
resources:
  server:
    type: OS::Nova::Server
    properties:
      image: { get_param: ImageID }
      flavor: m1.tiny
      networks:
      - network: { get_param: NetID }
 
outputs:
  private_ip:
    description: IP address of the server in the private network
    value: { get_attr: [ server, first_address ] }
    
EOF

NET_ID=$(nova net-list | awk '/ int_net / { print $2 }')

heat stack-create -f test-stack.yml -P "ImageID=cirros-0.3.3-x86_64;NetID=$NET_ID" testStack