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
