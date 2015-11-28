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
