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
```
hostnamectl set-hostname "undercloud.example.com"
dhclient -r && dhclient
echo "192.168.126.1 undercloud.example.com" >> /etc/hosts
```
Данные команды изменяют имя хоста, обновляют настройки сети (соединение иногда
пропадает, если изменить имя хоста - это зависит от настроек сети) и вносят адрес
в файл hosts.

```
yum update -y
```
Обновляет систему.
```
useradd stack
echo "enter_password_here" | passwd --stdin stack #CHANGE PASSWORD HERE
echo "stack ALL=(root) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/stack
chmod 0440 /etc/sudoers.d/stack
```
Здесь происходит создание нового пользователя с именем "stack", настраивается
его пароль (желательно его изменить) и настраивается разрешение пользователю
выполнять команду *sudo*.

```
yum -y install mlocate python-requests python3-pip yum-plugin-priorities epel-release vim wget
pip3 install requests
```
Здесь происходит установка всех необходимых в ходе установки утилит а также библиотеки requests.
```
updatedb
```
Данная команда генерирует базу данных для работы команды *locate*.

```
cp undercloud_install.sh /home/stack/undercloud_install.sh
chmod 777 /home/stack/undercloud_install.sh
cp my_undercloud.conf /home/stack/undercloud.conf
```
Здесь копируются файлы, необходимые для установки.
```
su - stack
```
Система переключается на пользователя stack.
#### Разбор скрипта undercloud_install.sh
