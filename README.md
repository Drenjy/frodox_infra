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
