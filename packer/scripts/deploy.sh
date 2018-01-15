#!/bin/bash

set -fuCe -o pipefail

cd ~

git clone https://github.com/Otus-DevOps-2017-11/reddit.git reddit
cd reddit
bundle install

sudo mv /tmp/pumad.service /etc/systemd/system/pumad.service
sudo systemctl enable pumad.service
