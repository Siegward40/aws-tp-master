#!/bin/bash
# cloud-init style
set -e
apt-get update -y
apt-get install -y docker.io git python3-pip
systemctl start docker
systemctl enable docker


# CLONE repo - vous pouvez changer cette URL via variables ou placer vos fichiers ici
# REMARQUE: Remplacez GIT_REPO par votre repo public contenant le dossier app/
GIT_REPO="https://github.com/REPLACE_ME/your-app-repo.git"


if [ "$GIT_REPO" != "" ]; then
cd /home/ubuntu
git clone $GIT_REPO app || true
cd app || exit 0
docker build -t lab-app:latest .
docker run -d --name lab-app -p 80:80 lab-app:latest
fi