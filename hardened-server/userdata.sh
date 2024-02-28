#!/bin/bash
echo "userdata-start"
yum update -y
yum upgrade -y
wait
yum install -y ansible git nginx aide
sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
setenforce 1
systemctl enable nginx
systemctl start nginx
update-crypto-policies --set DEFAULT
systemctl disable sshd
systemctl stop sshd
yum remove -y openssh-server
echo "userdata-end"
reboot
