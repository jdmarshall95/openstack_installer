repo_adress =$(sudo locate python2-tripleo-repos.noarch.rpm 2>&1)
rpm -ivh $repo_adres
sudo -E tripleo-repos -b stein current
sudo yum install python-tripleoclient -y
ruby_installer_adress = $(sudo locate ruby_install.sh 2>&1)
sudo chmod 777 $ruby_installer_adress
./$ruby_installer_adress
sudo yum -y downgrade leatherman

undercloud_sample_adress =$(sudo locate my_undercloud.conf 2>&1)
cp $undercloud_sample_adress undercloud.conf
openstack undercloud install
