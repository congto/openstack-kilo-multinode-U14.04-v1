#!/bin/bash -ex
#
source config.cfg

export OS_TOKEN="$TOKEN_PASS"
export OS_URL=http://$CON_MGNT_IP:35357/v2.0 
 
 
# export OS_SERVICE_TOKEN="$TOKEN_PASS"
# export OS_SERVICE_ENDPOINT="http://$CON_MGNT_IP:35357/v2.0"
# export SERVICE_ENDPOINT="http://$CON_MGNT_IP:35357/v2.0"

get_id () {
    echo `$@ | awk '/ id / { print $4 }'`
}

###  Identity service
openstack service create --name keystone --description "OpenStack Identity" identity
### Create the Identity service API endpoint
openstack endpoint create \
--publicurl http://$CON_MGNT_IP:5000/v2.0 \
--internalurl http://$CON_MGNT_IP:5000/v2.0 \
--adminurl http://$CON_MGNT_IP:35357/v2.0 \
--region RegionOne \
identity

#### To create tenants, users, and roles ADMIN
openstack project create --description "Admin Project" admin
openstack user create --password  $ADMIN_PASS admin
openstack role create admin
openstack role add --project admin --user admin admin

#### To create tenants, users, and roles  SERVICE
openstack project create --description "Service Project" service


#### To create tenants, users, and roles  DEMO
openstack project create --description "Demo Project" demo
openstack user create --password  $ADMIN_PASS demo

### Create the user role
openstack role create user
openstack role add --project demo --user demo user

#################

unset OS_TOKEN OS_URL

# Tao bien moi truong

echo "export OS_PROJECT_DOMAIN_ID=default" > admin-openrc.sh
echo "export OS_USER_DOMAIN_ID=default" >> admin-openrc.sh
echo "export OS_PROJECT_NAME=admin" >> admin-openrc.sh
echo "export OS_TENANT_NAME=admin" >> admin-openrc.sh
echo "export OS_USERNAME=admin" >> admin-openrc.sh
echo "export OS_PASSWORD=$ADMIN_PASS"  >> admin-openrc.sh
echo "export OS_AUTH_URL=http://$CON_MGNT_IP:35357/v3" >> admin-openrc.sh

