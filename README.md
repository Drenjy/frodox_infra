## HomeWork #5

Хост: **bastion**, IP: `35.205.232.11`, internal IP: `10.132.0.2`
Хост: **someinternalhost**, internal IP: `10.132.0.3`

### Подключение в одну команду

Команда: `ssh -t gcp-bastion ssh 10.132.0.3`
При этому в `~/.ssh/config` имеем:

```
Host gcp-bastion
    Hostname 35.205.232.11
    User appuser
    IdentityFile ~/.ssh/appuser
    ForwardAgent yes
```

### * Подключение в одну команду через алиас

Имеем в `~/.ssh/config` строки

```
Host gcp-bastion
    Hostname 35.205.232.11
    User appuser
    IdentityFile ~/.ssh/appuser
    ForwardAgent yes

Host gcp-internalhost
    Hostname 10.132.0.3
    User appuser
    Port 22
    IdentityFile ~/.ssh/appuser
    ProxyCommand ssh -q -W %h:%p gcp-bastion
```

и подключаемся к **internalhost** как `ssh gcp-internalhost`

## HomeWork #6

Создан puma-server с приложением на ruby работающим от пользователя appuser.
Адрес проверки: http://104.155.49.55:9292/

Команда gcp для создания инстанста со стартап скриптом:

```bash
gcloud compute instances create reddit-app \
    --boot-disk-size=10GB  \
    --image-family ubuntu-1604-lts \
    --image-project=ubuntu-os-cloud \
    --machine-type=g1-small \
    --tags puma-server \
    --restart-on-failure \
    --metadata-from-file startup-script=startup_script.sh
```

Команда для добавления правила firewall

```bash
gcloud compute firewall-rules create default-puma-server  \
    --direction=INGRESS  \
    --priority=1000  \
    --network=default  \
    --action=ALLOW  --rules=tcp:9292  \
    --source-ranges=0.0.0.0/0  \
    --target-tags=puma-server
```


## Homework 7 (packer)

Добавлен шаблон `ubuntu16.json` для создания образа семейства `reddit-base`,
который содержит ruby и mongodb.

Переменные обязательные к указанию:
* `project_id` - project id в GCP, где создавать образ
* `source_image_family` - семейство базового образа, на котором будет основан наш.

Доступные для перезаписи переменные:
* `img_description` - описание образа
* `disk_size_gb` - размер образа
* `disk_gcp_type` - тип диска
* `machine_type` - тип машины *на время создания образа*
* `network_name` - имя используемой сети *на время создания образа*
* `tags` - теги машины *на время создания образа*

Пример переменных приведён в `variables.json.example`.
Сборка образа:

```
packer build -var-file=variables.json ubuntu16.json
```

Так же добавлен конфиг `immutable.json` для создания baked-образа `reddit-full`.
Конфигурация и настройки - аналогичны. Сборка:

```
packer build -var-file=variables.json immutable.json
```

Добавлен скрипт создания VM на основе созданного образа `create-reddit-vm.sh`.


## Homework 8 (terraform)

Описана инфраструктура для приложения puma в виде кода terraform.
* `main.tf` - основной файл описания ВМ и её настроек
* `variables.tf` - переменные что можно переопределить на лету
* `terraform.tfvars.example` - скопировать этот файл с примерами значений переменных как
  `terraform.tfvars` и задать свои значения для удобства
* `output.tfvars` - доп.переменные что задаются для удобства на основе выполнения команд инфраструктуры

в каталоге `files/` находятся скрипты для авто-деплоя приложения puma на созданную ВМ.

### sshKeys

При добавлении ssh-ключей в веб-интерфейсе в метаданные инстанса ВМ - они будут перетёрты после
`terraform apply`, т.к. они не указаны в коде в описании ВМ.

При добавлении ssh-ключей в веб-интерфейсе в рамках метаданных проекта, то они будут
игнорироваться, если на уровне метаданных ВМ используется deprecated опция `sshKeys`.

## Homework 9 (terraform 2)

Описание инфраструктуры разделено на части:
* `modules/app` - модуль с приложением
* `modules/db` - модуль с MongoDB
* `stage/` - настройки ВМ для тестового окружения
* `prod/` - настройки ВМ для боевого окружения

Для работы требуется сперва создать образы дисков (app и db) командой
```bash
cd packer/
packer build -var-file=variables.json db.json
packer build -var-file=variables.json app.json
```

Далее для использования stage/prod окружения требуется сперва выполнить
```bash
terraform init
terraform get
```

и создать `terraform.tfvars` со своими данными.


## Homework 10 (Ansible)

В уроке создана база для дальнейшей реализации подхода IaC.

Для начала работы, установим необходимые пакеты
```bash
cd ansible/
sudo pip install -r requirements.txt
```

* В `inventory` имеет список хостов в ini формате.
* В `ansible.cfg` - общие настройки для ansible.

Проверяем доступность всех узлов через
```
ansible all -m ping
```
Если всё ок, можем вызывать точечные модули под задачи.


## Homework 11 (Ansible)

### Один плейбук, один сценарий

Для деплоя и запуска приложения требуется выполнить:
```
cd terraform/stage
terraform apply -auto-approve=true

# исправляем IP в ansible/inventory
# исправляем db_host в сценариях

cd ../ansible
ansible-playbook reddit_app_one_play.yml --tags db-tag -l db
ansible-playbook reddit_app_one_play.yml --tags app-tag -l app
ansible-playbook reddit_app_one_play.yml --tags deploy-tag -l app
```
Проверяем наше приложение по адресу `app_external_ip:9292`.


### Один плейбук, много сценариев

Для деплоя и запуска приложения требуется выполнить:
```
cd terraform/stage
terraform destroy
terraform apply -auto-approve=true

# исправляем IP в ansible/inventory
# исправляем db_host в сценариях

cd ../ansible
ansible-playbook reddit_app_multiple_plays.yml --tags db-tag
ansible-playbook reddit_app_multiple_plays.yml --tags app-tag
ansible-playbook reddit_app_multiple_plays.yml --tags deploy-tag
```
Проверяем наше приложение по адресу `app_external_ip:9292`.


### Много плейбуков

Для деплоя и запуска приложения требуется выполнить:
```
cd terraform/stage/
terraform destroy
terraform apply -auto-approve=true

# исправляем IP в ansible/inventory
# исправляем db_host в сценариях

cd ../ansible
ansible-playbook site.yml
```
Проверяем наше приложение по адресу `app_external_ip:9292`.


### Интеграция с packer

Для запуска теста интеграции с packer требуется выполнить
```
# из корня репозитория

## для создания правила firewall для ssh
cd terraform/stage/
terraform apply
cd ../..

packer build -var-file=packer/variables.json packer/app.json &
packer build -var-file=packer/variables.json packer/db.json &
wait

cd ../terraform/stage/
terraform destroy
terraform apply

cd ../../ansible/
ansible-playbook site.yml
```
Проверяем наше приложение по адресу `app_external_ip:9292`.


## Homework 12 (Ansible)

Используем роли, environment и публичную роль nginx.

* `roles/app` - роль приложения
* `roles/db` - роль БД
* `playbooks` - тут хранятся все плейбуки

Параметры по умолчанию для переопределения в `roles/<name>/defaults/*.yml`.

Имеем два окружения - `stage` и `prod`. Запуск на конкретное окружение осуществляется через команду

```
ansible-playbook playbooks/site.yml -i environments/<env_name>/inventory
```

Окружение по умолчанию (задано в `ansible.cfg`) --- `stage`.
Предварительно необходимо установить зависимости для окружения из Ansible Galaxy:

```
ansible-galaxy install -r environments/<env_name>/requirements.yml
```

Для роли nginx также открыт в firewall 80-й порт.


## Homework 13 (Ansible)

### Настройка Vagrant окружения для локального тестирования

В ходе ДЗ был добавлен `ansible/Vagrantfile` для локального тестирования
инфраструктуры (и деплоя через ansible). 
Команды управление инфрой (из каталога `ansible`):

* `vagrant up` --- поднять виртуальное окружение
* `vagrant destroy -f` --- удалить окружение
* `vagrant status` --- посмотреть статус - поднятые хосты и т.п.
* `vagrant ssh <host>` --- подключиться по ssh к указанному хосту

Так же добавлен `playbooks/base.yml` для установки python для ansible через raw-модуль, на тот случай, там где его нет.


### Тестирование ansible роли

Для тестирования ролей ansible используется утилита Molucule и фреймворк Testinfra. Сперва необходимо подготовить окружение, установив зависимости:

```
cd ansible
virtualenv-2.7 .venv
source .venv/bin/activate
pip2 install --upgrade pip
pip2 install -r requirements.txt
```

Затем можем переходить непосредственно к тестированию. Основные команды и файлы:

* `molecule init scenario --scenario-name default -r db -d vagrant` --- инициализация окружения для тестирования конкретной роли с драйвером vagrant (выполняется из каталога роли)
* `db/molecule/default/tests/test_default.py` --- тесты роли. Пишутся с использованием флеймворка 
* `db/molecule/default/molecule.yml` --- описание машины, которая создаётся Molecule для тестов
* `db/molecule/default/playbook.yml` --- плейбук для вызова нашей роли, которую мы тестируем
* `molecule create` --- создание и запуск машины для тестов
* `molecule list` --- список созданных инстансов
* `molecule converge` --- применение конфигурации `playbook.yml` к созданной машине
* `molecule verify` --- запуск и проверка всех тестов


### Адаптация packer под новую ansible-структуру

Вызов packer остался неизменен. Изменились json-шаблоны.

```
# из корневого каталога репозитория
packer build -var-file=packer/variables.json packer/app.json
packer build -var-file=packer/variables.json packer/db.json
```
