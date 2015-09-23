#!/bin/bash -ex
source config.cfg

## Create a Swift user, endpoint
openstack user create --password $ADMIN_PASS swift
openstack role add --project service --user swift admin
openstack service create --name swift --description "OpenStack Object Storage" object-store

openstack endpoint create \
--publicurl http://$CON_MGNT_IP:8080/v1/AUTH_%(tenant_id)s \
--internalurl http://$CON_MGNT_IP:8080/v1/AUTH_%(tenant_id)s \
--adminurl http://$CON_MGNT_IP:8080 \
--region RegionOne \
object-store

  
echo "##############Install SWIFT###############"
apt-get -y install swift swift-proxy python-swiftclient python-keystoneclient python-keystonemiddleware memcached

mkdir -p /etc/swift/

fileswift=/etc/swift/proxy-server.conf
cat << EOF > $fileswift

[DEFAULT]
bind_port = 8080
user = swift
swift_dir = /etc/swift


[pipeline:main]
pipeline = catch_errors gatekeeper healthcheck proxy-logging cache container_sync bulk ratelimit authtoken keystoneauth container-quotas account-quotas slo dlo proxy-logging proxy-server


[app:proxy-server]
use = egg:swift#proxy
account_autocreate = true


[filter:keystoneauth]
use = egg:swift#keystoneauth
operator_roles = admin,user


[filter:authtoken]
paste.filter_factory = keystonemiddleware.auth_token:filter_factory
auth_uri = http://$CON_MGNT_IP:5000
auth_url = http://$CON_MGNT_IP:35357
auth_plugin = password
project_domain_id = default
user_domain_id = default
project_name = service
username = swift
password = $SWIFT_PASS
delay_auth_decision = true



[filter:tempauth]
use = egg:swift#tempauth
user_admin_admin = admin .admin .reseller_admin
user_test_tester = testing .admin
user_test2_tester2 = testing2 .admin
user_test_tester3 = testing3
user_test5_tester5 = testing5 service
[filter:healthcheck]
use = egg:swift#healthcheck
[filter:cache]
use = egg:swift#memcache
memcache_servers = 127.0.0.1:11211

[filter:ratelimit]
use = egg:swift#ratelimit
[filter:domain_remap]
use = egg:swift#domain_remap
[filter:catch_errors]
use = egg:swift#catch_errors
[filter:cname_lookup]
use = egg:swift#cname_lookup
[filter:staticweb]
use = egg:swift#staticweb
[filter:tempurl]
use = egg:swift#tempurl
[filter:formpost]
use = egg:swift#formpost
[filter:name_check]
use = egg:swift#name_check
[filter:list-endpoints]
use = egg:swift#list_endpoints
[filter:proxy-logging]
use = egg:swift#proxy_logging
[filter:bulk]
use = egg:swift#bulk
[filter:slo]
use = egg:swift#slo
[filter:dlo]
use = egg:swift#dlo
[filter:container-quotas]
use = egg:swift#container_quotas
[filter:account-quotas]
use = egg:swift#account_quotas
[filter:gatekeeper]
use = egg:swift#gatekeeper
[filter:container_sync]
use = egg:swift#container_sync
[filter:xprofile]
use = egg:swift#xprofile

EOF


