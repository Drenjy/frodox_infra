#!/bin/bash

set -fuC -o pipefail

apt update
apt install -y ruby-full ruby-bundler build-essential

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927

bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse"' > /etc/apt/sources.list.d/mongodb-org-3.2.list

apt update
apt install -y mongodb-org
systemctl start mongod
systemctl enable mongod

sudo -u appuser bash << EOF

cd ~

git clone https://github.com/Otus-DevOps-2017-11/reddit.git reddit
cd reddit
bundle install
puma -d

EOF

