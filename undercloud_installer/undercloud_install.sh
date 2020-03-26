repo_adress=$(sudo locate python2-tripleo-repos.noarch.rpm)
sudo rpm -ivh $repo_adress
sudo -E tripleo-repos -b stein current
sudo yum -y install python-tripleoclient leatherman
sudo yum -y downgrade leatherman
facter
ruby_installer_adress=$(sudo locate ruby_install.sh)
sudo cp $ruby_installer_adress ruby_install.sh
sudo chmod 777 ruby_install.sh
sudo ./ruby_install.sh
openstack undercloud install
