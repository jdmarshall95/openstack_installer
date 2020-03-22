#!/bin/bash

hostnamectl set-hostname "undercloud.example.com"
exec bash
dhclient -r && dhclient
echo "192.168.126.1 undercloud.example.com" >> /etc/hosts
yum update -y
useradd stack
echo "enter_password_here" | passwd --stdin stack
echo "stack ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
yum -y install mlocate python-requests python3-pip yum-plugin-priorities epel-release vim


updatedb
pip3 install requests
su - stack  #preparation part ends here

repo_adress =$(locate python2-tripleo-repos.noarch.rpm 2>&1)
rpm -ivh $repo_adress
sudo -E tripleo-repos -b stein current
sudo yum install python-tripleoclient -y
ruby_installer_adress = $(locate ruby_install.sh 2>&1)
sudo chmod 777 $ruby_installer_adress
./$ruby_installer_adress
sudo yum -y downgrade leatherman

undercloud_sample_adress =$(locate my_undercloud.conf 2>&1)
cp $undercloud_sample_adress undercloud.conf
openstack undercloud install
