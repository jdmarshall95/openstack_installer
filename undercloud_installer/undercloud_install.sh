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
