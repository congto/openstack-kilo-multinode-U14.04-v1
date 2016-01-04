#!/bin/bash -ex
#
source config.cfg
#

apt-get -y install ceilometer-agent-compute

mv /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.bka
cat << EOF > /etc/ceilometer/ceilometer.conf
[DEFAULT]
rpc_backend = rabbit
verbose = True

[database]

[keystone_authtoken]
auth_uri = http://$CON_MGNT_IP:5000/v2.0
identity_uri = http://$CON_MGNT_IP:35357
admin_tenant_name = service
admin_user = ceilometer
admin_password = $CEILOMETER_PASS

[matchmaker_redis]
[matchmaker_ring]
[oslo_messaging_amqp]
[oslo_messaging_qpid]

[oslo_messaging_rabbit]
rabbit_host = $CON_MGNT_IP
rabbit_userid = openstack
rabbit_password = $RABBIT_PASS

[publisher]
telemetry_secret = $METERING_SECRET

[service_credentials]
os_auth_url = http://$CON_MGNT_IP:5000/v2.0
os_username = ceilometer
os_tenant_name = service
os_password = $CEILOMETER_PASS
os_endpoint_type = internalURL
os_region_name = RegionOne

EOF

service ceilometer-agent-compute restart
service nova-compute restart
