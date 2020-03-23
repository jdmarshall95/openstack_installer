#!/bin/bash

hostnamectl set-hostname "undercloud.example.com"
echo "192.168.126.1 undercloud.example.com" >> /etc/hosts
yum update -y
useradd stack
echo "enter_password_here" | passwd --stdin stack #CHANGE PASSWORD HERE
echo "stack ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
yum -y install mlocate python-requests git python3-pip yum-plugin-priorities epel-release vim wget
pip3 install requests
updatedb
cp undercloud_install.sh /home/stack/undercloud_install.sh
cp ../overcloud_installer/instackenv.json /home/stack/instackenv.json
cp ../overcloud_install/overcloud_install.sh /home/stack/overcloud_install.sh
chmod 777 /home/stack/overcloud_install.sh
chmod 777 /home/stack/undercloud_install.sh
cp my_undercloud.conf /home/stack/undercloud.conf
su - stack  #preparation part ends here
