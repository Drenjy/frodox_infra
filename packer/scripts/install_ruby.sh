#!/bin/bash

set -fuCe -o pipefail

apt update
apt install -y ruby-full ruby-bundler build-essential
