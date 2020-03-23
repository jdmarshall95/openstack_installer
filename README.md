# openstack_installer
## Развертывание базового openstack

### Общие рекомендации

Все действия на удаленном сервере лучше выполнять в терминале *tmux*, чтобы не
потерять прогресс, если оборвется соединение.

### Глава 0. Подготовка к развертыванию
#### Тестовое развертывание в виртуальной среде
При создании виртуальной машины стоит указать 2 сетевых интерфейса (пример в
ESXI):
![ESXI](https://i.imgur.com/8gFZuty.png)
#### Установка операционной ситсемы для Undercloud
Во время установки CentOS 7 стоит включить сетевой интерфейс №1:
![Installation](https://i.imgur.com/xzIQDqQ.png)
#### Требования к железу
Так же стоит учитывать, что на сервере, где будет установлен undercloud
должно быть доступно около 32 ГБ оперативной памяти (минимум 24).
#### Настройка коммутатора
Для корректной  работы openstack необходимо настроить vlan-ы на коммутаторе. Необходимо зайти на веб-интерфейс своего коммутатора и создать 8 vlan-ов с различными ID:
![Vlans](https://i.imgur.com/SgnFrsY.png)
Названия в данном случае не играют никакой роли. ID так же можно указывать на свой вкус.
Далее стоит настроить созданные vlan-ы следующим образом:
<ol>
<li>Сеть, вкоторую включен первый интерфейс undercloud (можно всех серверов, как правило они называются enp1s0f0 в CentOS 7), управляющие платы (ipmi, idrac, ilo), а так же uplink коммутатора - все untagged.</li>
<li>Сеть, в которую включены вторые интерфейсы серверов (enp1s0f1) - так же untagged.</li>
<li>Все оставшиеся имеют одинаковую конфигурацию - все интерфейсы серверов + uplink в tagged.</li>
</ol>
На самом деле настройки коммутатора подбираются практически всегда индивидуально, в зависимости от общей конфигурации сети.

### Глава 1. Полуавтоматическая установка openstack
#### Установка undercloud
В данном репозитории представленно все необходимое для установки undercloud.
Первым делом необходимо склонировать его командой:
<pre><code>git clone https://github.com/hiraetari/openstack_installer.git</code></pre>
Далее необходимо перейти в директорию с установочными скриптами с помощью команды:
<pre><code>cd openstack_installer/undercloud_installer</code></pre>
Необходимо настроить поставляемый файл my_undercloud.conf, а именно внести в него
информацию о локальном интерфейсе (список интерфейсов можно вывести командой <code>ip a</code>),
необходимо в данном файле переменной *local_interface* присвоить значение имени второго аппаратного интерфейса (lo - виртуальный интерфейс). Также в файле **preparation.sh** стоит заменить фразу "enter_password_here" на пароль. Для всех вышеперечисленных действий подойдет любой текстовый редактор (по умолчани в CentOS 7 стоит *vi*, но можно установить любой другой - *nano*, *vim* итд).
Делаем файл **preparation.sh** исполняемым <code>chmod 777 preparation.sh</code>
И запускаем установку командой <code>./preparation.sh</code>

Когда скрипт отработает, система автоматически переключится на пользователя stack и необходимо будет запустить скрипт установки командой <code>./ undercloud_install.sh </code>
Успешная установка undercloud выглядит следующим образом:
![Undercloud](https://i.imgur.com/1VLqTYn.png)
#### Установка overcloud
Перед установкой overcloud необходимо настроить файл instackenv.json, он определяет конфигурацию серверов (нод), на которых будет развернут overcloud. Информация об одной ноде выглядит примерно следующим образом:
```
{
    "name":"node_name", # Имя ноды
    "pm_type":"pxe_ipmitool", # Тип управляющей платы ноды
    "mac":[
        "00:25:90:34:14:17" # Мак адрес интерфейса, с которого происходит загрузка по PXE
    ],
    "cpu":"8", # Число ядер (потоков) сервера
    "memory":"40", # Объем памяти сервера (ГБ)
    "disk":"1000", #Объем дискового пространства сервера (МБ)
    "arch":"x86_64", #Архитектура сервера
    "pm_user":"ADMIN", № Логин от управляющей платы
    "pm_password":"ADMIN", #Пароль от управляющей платы
    "pm_addr":"10.133.102.176" # Адрес управляющей платы
}
```
В данный файл необходимо внести информацию обо всех нодах, на которых планируется развернуть overcloud.
Также необходимо отредактировать поля с комментариями в файле *overcloud_install.sh* (имена серверов, заданные в instackenv.json) и добавить новые при необходимости.
Далее необходимо запустить скрипт командой <code>./overcloud_install.sh</code>
Успешный результат работы скрипта выглядит приблизительно вот так:
```
Ansible passed.
Overcloud configuration completed.
Waiting for messages on queue 'tripleo' with no timeout.
Host 10.133.102.12 not found in /home/stack/.ssh/known_hosts
Overcloud Endpoint: http://10.133.102.12:5000
Overcloud Horizon Dashboard URL: http://10.133.102.12:80/dashboard
Overcloud rc file: /home/stack/overcloudrc
Overcloud Deployed
```
После выполнения скрипта станет доступен полноценный openstack.
![Openstack](https://i.imgur.com/mCrg446.png)
В следущей главе мы рассмотрим действия, выполняемые данными скриптами подробнее
### Глава 2. Разбор содержимого скриптов (ручная установка)

#### Разбор скрипта preparation.sh
Первый скрипт **preparation.sh** подготавливает систему к установке undercloud.
```Shell
hostnamectl set-hostname "undercloud.example.com"
echo "192.168.126.1 undercloud.example.com" >> /etc/hosts
```
Данные команды изменяют имя хоста и вносят адрес в файл hosts.
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
Здесь происходит создание нового пользователя с именем "stack", настраивается право выполнять команду *sudo*.

```Shell
yum -y install mlocate python-requests git python3-pip yum-plugin-priorities epel-release vim wget
pip3 install requests
```
Здесь происходит установка всех необходимых в ходе установки утилит а также
библиотеки requests.
```Shell
updatedb
```
Данная команда генерирует базу данных для работы команды *locate*.

```Shell
cp undercloud_install.sh /home/stack/undercloud_install.sh
cp ../overcloud_installer/instackenv.json /home/stack/instackenv.json
cp ../overcloud_install/overcloud_install.sh /home/stack/overcloud_install.sh
chmod 777 /home/stack/overcloud_install.sh
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
Здесь происходит установка репозиториев tripleo и выбор версии stein. В репозитории находится версия 2020-03-10 03:18, однако, при желании можно скачать [отсюда](https://trunk.rdoproject.org/centos7/current/) наиболее свежую версию - переходим по ссылке, находим самый свежий *python2-tripleo-repos*, копируем адрес и скачиваем файл с помощью *wget* (данный функционал не предусматривается автоматическим развертыванием).

```Shell
sudo yum -y install python-tripleoclient leatherman
```
Скачивание файлов openstack из подключенного выше репозитория.

Далее будут призведены действия, необходимые для работы *данной* версии openstack, на других версиях они могут отличаться (стоит читать вывод комманд и по ситуации смотреть что именно идет не так).

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
#### Разбор скрипта overcloud_install.sh
