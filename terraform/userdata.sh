set -e
apt-get update -y
apt-get install -y docker.io git python3-pip

systemctl start docker
systemctl enable docker

git clone