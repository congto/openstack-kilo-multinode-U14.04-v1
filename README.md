# Script cài đặt OpenStack KILO
- Tách các node CONTROLLER, NETWORK, COMPUTE, CINDER, SWIFT


### Thực hiện trên CONTROLLER

```sh
su -

apt-get update
apt-get -y install git

git clone https://github.com/congto/openstack-kilo-multinode-U14.04-v1.git
mv openstack-kilo-multinode-U14.04-v1/KILO-U14.04/ /root/
rm -rf openstack-kilo-multinode-U14.04-v1
cd KILO-U14.04
chmod +x *.sh

```

- Sửa file config.cfg với các IP dự định sẽ setup
- Thực thi script đầu tiên

```sh
bash ctl-1-ipadd.sh
```

- Máy sẽ khởi động lại sau khi thực thi script trên, đăng nhập với quyền root và thực thi script tiếp theo
```sh
su -
bash ctl-2-prepare.sh
```

- Thực thi script tạo DB
```sh
bash ctl-3-create-db.sh
```

- Thực thi script cài Keystone
```sh
bash ctl-4.keystone.sh
```

- Thực thi script tạo user, role trong Keystone
```sh
bash ctl-5-creatusetenant.sh
```

- Chạy script khai báo biến môi trường
```sh
source admin-openrc.sh
```

- Chạy scirpt cài đặt glance
```sh
bash ctl-6-glance.sh
```

- Chạy script cài đặt nova
```sh
bash ctl-7-nova.sh
```

- Cài đặt Neutron
```sh
bash ctl-8-neutron.sh
```

- Cài đặt CINDER
```sh
- Nếu node CONTROLLER có HDD dành cho Cinder thì chạy script ctl-9-cinder-ctl-AIO.sh

bash ctl-9-cinder-ctl-AIO.sh

- Nếu node CINDER-VOLUME được tách ra thì sử dụng script ctl-9-cinder.sh

bash ctl-9-cinder.sh
```

- Cài đặt CEILOMTER
```bash
ctl-12-ceilometers.sh

Chú ý: Cần cài cả CEILOMTER trên COMPUTE NODE, CINDER NODE, SWIFT NODE
```


- Cài đặt Horizon
```sh
bash ctl-horizon.sh
```

### Cài đặt trên `NETWORK NODE`

```sh
su -

apt-get update
apt-get -y install git

git clone https://github.com/congto/openstack-kilo-multinode-U14.04-v1.git
mv openstack-kilo-multinode-U14.04-v1/KILO-U14.04/ /root/
rm -rf openstack-kilo-multinode-U14.04-v1
cd KILO-U14.04
chmod +x *.sh
```

- Sửa file config.cfg tương tự như trên node `CONTROLLER`
- Thực thi script 
```sh
bash net-ipadd.sh
```

- Đăng nhập lại và thực thi tiếp scirpt 
```sh
bash net-prepare.sh
```

### Cài đặt trên `COMPUTE1 NODE`

```sh
su -

apt-get update
apt-get -y install git

git clone https://github.com/congto/openstack-kilo-multinode-U14.04-v1.git
mv openstack-kilo-multinode-U14.04-v1/KILO-U14.04/ /root/
rm -rf openstack-kilo-multinode-U14.04-v1
cd KILO-U14.04
chmod +x *.sh
```

- Sửa file config.cfg tương tự như trên node `CONTROLLER`
- Thực thi script dưới

```sh
bash com1-ipdd.sh
```

```sh
bash com1-prepare.sh
```


- Nếu cài đặt CEILOMTER thì thực hiện thêm script
```sh
bash com1-ceilomter.sh
```