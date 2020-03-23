# openstack_installer
## Развертывание базового openstack

### Глава 1. Полуавтоматическая установка undercloud

В данном репозитории представленно все необходимое для установки undercloud.
Первым делом необходимо склонировать его командой:
<pre><code>git clone https://github.com/hiraetari/openstack_installer.git</code></pre>
Далее необходимо перейти в директорию с установочными скриптами с помощью команды:
<pre><code>cd openstack_installer/undercloud_installer</code></pre>
Необходимо настроить поставляемый файл my_undercloud.conf, а именно внести в него
информацию о локальном интерфейсе (список интерфейсов можно вывести командой <code>ip a</code>),
необходимо в данном файле переменной *local_interface* присвоить значение второго
аппаратного интерфейса (lo - виртуальный интерфейс).
Также в файле **preparation.sh** стоит заменить фразу "enter_password_here" на пароль.
Для всех вышеперечисленных действий
подойдет любой текстовый редактор (по умолчани в CentOS 7 стоит *vi*, но можно
установить любой другой - *nano*, *vim* итд).

Делаем файл **preparation.sh** исполняемым <code>chmod 777 preparation.sh</code>
И запускаем установку командой <code>./preparation.sh</code>

Когда скрипт отработает, система автоматически переключится на пользователя stack
 и необходимо будет запустить скрипт
установки командой <code>./undercloud_install.sh </code>

В следущей главе мы рассмотрим действия, выполняемые данными скриптами подробнее
### Глава 2. Разбор содержимого скриптов (ручная установка)

#### Разбор скрипта preparation.sh
Первый скрипт **preparation.sh** подготавливает систему к установке undercloud.
```Shell
hostnamectl set-hostname "undercloud.example.com"
dhclient -r && dhclient
echo "192.168.126.1 undercloud.example.com" >> /etc/hosts
```
Данные команды изменяют имя хоста, обновляют настройки сети (соединение иногда
пропадает, если изменить имя хоста - это зависит от настроек сети) и вносят адрес
в файл hosts.

```Shell
yum update -y
```
Обновляет систему.
```Shell
useradd stack
echo "enter_password_here" | passwd --stdin stack #CHANGE PASSWORD HERE
echo "stack ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
```
Здесь происходит создание нового пользователя с именем "stack", настраивается
его пароль (желательно его изменить) и настраивается разрешение пользователю
выполнять команду *sudo*.

```Shell
yum -y install mlocate python-requests python3-pip yum-plugin-priorities epel-release vim wget
pip3 install requests
```
Здесь происходит установка всех необходимых в ходе установки утилит а также библиотеки requests.
```Shell
updatedb
```
Данная команда генерирует базу данных для работы команды *locate*.

```Shell
cp undercloud_install.sh /home/stack/undercloud_install.sh
chmod 777 /home/stack/undercloud_install.sh
cp my_undercloud.conf /home/stack/undercloud.conf
```
Здесь копируются файлы, необходимые для установки.
```Shell
su - stack
```
Система переключается на пользователя stack.
#### Разбор скрипта undercloud_install.sh
```Shell
repo_adress=$(sudo locate python2-tripleo-repos.noarch.rpm) ##сохранение адреса .rpm файла в переменную
sudo rpm -ivh $repo_adress
sudo -E tripleo-repos -b stein current
```
Здесь происходит установка репозиториев tripleo и выбор версии stein.
В репозитории находится версия 2020-03-10 03:18, однако, при желании можно
скачать [отсюда](https://trunk.rdoproject.org/centos7/current/) наиболее
свежую версию - переходим по ссылке, находим самый свежий
*python2-tripleo-repos*, копируем адрес и скачиваем файл с помощью *wget*
(данный функционал не предусматривается автоматическим развертыванием).

```Shell
sudo yum install python-tripleoclient -y
```
Скачивание файлов openstack из подключенного выше репозитория.

Далее будут призведены действия, необходимые для работы *данной* версии
openstack, на других версиях они могут отличаться (стоит читать вывод комманд
и по ситуации смотреть что именно идет не так).

```Shell
sudo yum -y downgrade leatherman
```
Даунгрейд библиотеки lethermman, для работы facter.

```Shell
ruby_installer_adress=$(sudo locate ruby_install.sh)
sudo cp $ruby_installer_adress ruby_install.sh
sudo chmod 777 ruby_install.sh
sudo ./ruby_install.sh
```
Установка ruby версии 2.6.3, rubygems и chef с помощью скрипта.
```
openstack undercloud install
```
Собственно, установка undercloud

#### (Опционально) Разбор скрипта ruby_install.sh
```Shell
cd  /tmp
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
```
Подключение репозитория epel (используется конкретная версия, на других
стабильность не гарантируется).

```Shell
yum -y update
yum -y groupinstall "Development Tools"
yum -y install libxslt-devel libyaml-devel libxml2-devel gdbm-devel libffi-devel zlib-devel openssl-devel libyaml-devel readline-devel curl-devel openssl-devel pcre-devel git memcached-devel valgrind-devel mysql-devel ImageMagick-devel ImageMagick
```
Установка утилит, для настройки и установки ruby.

```Shell
version=2.6.3
cd /usr/local/src
wget https://cache.ruby-lang.org/pub/ruby/2.6/ruby-$version.tar.gz
tar zxvf ruby-$version.tar.gz
cd ruby-$version
./configure
make
make install
```
Скачивание исходных кодов ruby их сборка и установка.

```Shell
version=3.0.3
cd ..
wget https://rubygems.org/rubygems/rubygems-$version.tgz
tar zxvf rubygems-$version.tgz
cd rubygems-$version
/usr/local/bin/ruby setup.rb

```
То же самое для ruby-gems

```Shell
gem install bundler chef ruby-shadow --no-ri --no-rdoc
```
Установка chef-solo
