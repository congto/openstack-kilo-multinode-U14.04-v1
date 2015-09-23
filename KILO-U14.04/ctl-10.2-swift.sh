#!/bin/bash -ex
source config.cfg

apt-get install expect -y

#Account ring
cd /etc/swift
swift-ring-builder account.builder create 10 3 1

swift-ring-builder account.builder add r1z1-$SWIFT1_MGNT_IP:6002/vdb 100
swift-ring-builder account.builder add r1z1-$SWIFT1_MGNT_IP:6002/vdc 100

swift-ring-builder account.builder add r1z1-$SWIFT2_MGNT_IP:6002/vdb 100
swift-ring-builder account.builder add r1z1-$SWIFT2_MGNT_IP:6002/vdc 100

swift-ring-builder account.builder
swift-ring-builder account.builder rebalance

#  Container ring
swift-ring-builder container.builder create 10 3 1
swift-ring-builder container.builder add r1z1-$SWIFT1_MGNT_IP:6001/vdb 100
swift-ring-builder container.builder add r1z1-$SWIFT1_MGNT_IP:6001/vdc 100

swift-ring-builder container.builder add r1z1-$SWIFT2_MGNT_IP:6001/vdb 100
swift-ring-builder container.builder add r1z1-$SWIFT2_MGNT_IP:6001/vdc 100

swift-ring-builder container.builder
swift-ring-builder container.builder rebalance

# Object ring

swift-ring-builder object.builder create 10 3 1
swift-ring-builder object.builder add r1z1-$SWIFT1_MGNT_IP:6000/vdb 100
swift-ring-builder object.builder add r1z1-$SWIFT1_MGNT_IP:6000/vdc 100

swift-ring-builder object.builder add r1z1-$SWIFT2_MGNT_IP:6000/vdb 100
swift-ring-builder object.builder add r1z1-$SWIFT2_MGNT_IP:6000/vdc 100

swift-ring-builder object.builder
swift-ring-builder object.builder rebalance




 cat << EOF >  /etc/swift/swift.conf
[swift-hash]
swift_hash_path_prefix = xrfuniounenqjnw
swift_hash_path_suffix = fLIbertYgibbitZ

[storage-policy:0]
name = Policy-0
default = yes
[swift-constraints]

EOF


sleep 3

/usr/bin/expect <<EOD
spawn scp  container.ring.gz object.ring.gz account.ring.gz  root@$SWIFT1_MGNT_IP:/etc/swift
#######################
expect {
-re ".*es.*o.*" {
exp_send "yes\r"
exp_continue
}
-re ".*sword.*" {
exp_send "$PASS_ROOT\r"
}
}
expect eof
EOD


sleep 3

/usr/bin/expect <<EOD
spawn scp  container.ring.gz object.ring.gz account.ring.gz  root@$SWIFT2_MGNT_IP:/etc/swift
#######################
expect {
-re ".*es.*o.*" {
exp_send "yes\r"
exp_continue
}
-re ".*sword.*" {
exp_send "$PASS_ROOT\r"
}
}
expect eof
EOD

chown -R swift:swift /etc/swift

service memcached restart
service swift-proxy restart
### KET THUC ###