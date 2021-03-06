#!/usr/bin/env bash

umask 000
git clone https://github.com/Niram7777/nvidia-docker.git
sudo make ubuntu-latest -C nvidia-docker &> nvidia-docker.log
sudo docker build --build-arg U_ID="$(id -u)" --build-arg G_ID="$(id -g)" -t rpcs3 - < Dockerfile &> rpcs3-docker.log
source .dockerrc
docker_rpcs3 -u -m -t -c
bash <(curl -s https://codecov.io/bash) -s coverage/

