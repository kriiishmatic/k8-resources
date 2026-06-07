#!/bin/bash

set -euxo pipefail

echo "========== Starting Bootstrap =========="

echo "========== Resizing Disk =========="
growpart /dev/nvme0n1 4 || true
lvextend -L +10G /dev/mapper/RootVG-varVol 
lvextend -L +10G /dev/mapper/RootVG-rootVol 
lvextend -l +100%FREE /dev/mapper/RootVG-homeVol 
xfs_growfs / 
xfs_growfs /var 
xfs_growfs /home

echo "========== Updating System =========="
# dnf update -y
dnf install -y \
  git \
  jq \
  wget \
  unzip \
  tar \
  curl \
  bind-utils \
  net-tools \
  tree \
  yum-utils

echo "========== Java =========="
dnf install -y java-21-openjdk

echo "========== Docker =========="
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

dnf install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

echo "========== Terraform =========="
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

dnf install -y terraform

echo "========== Helm =========="
curl -fsSL -o get_helm.sh \
  https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh
./get_helm.sh

rm -f get_helm.sh

echo "========== kubectl =========="
curl -LO \
  "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

mv kubectl /usr/local/bin/

echo "========== eksctl =========="
ARCH=amd64
PLATFORM=$(uname -s)_${ARCH}

curl -sLO \
  "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_${PLATFORM}.tar.gz"

tar -xzf eksctl_${PLATFORM}.tar.gz -C /tmp

install -m 0755 /tmp/eksctl /usr/local/bin

rm -f eksctl_${PLATFORM}.tar.gz
rm -f /tmp/eksctl

echo "========== kubectx / kubens =========="
rm -rf /opt/kubectx
git clone https://github.com/ahmetb/kubectx /opt/kubectx

ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx
ln -sf /opt/kubectx/kubens /usr/local/bin/kubens

echo "========== k9s =========="
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)

curl -Lo /tmp/k9s.tar.gz \
  https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz

tar -xzf /tmp/k9s.tar.gz -C /tmp

install -m 755 /tmp/k9s /usr/local/bin/k9s

rm -f /tmp/k9s.tar.gz
rm -f /tmp/k9s

echo "========== Bash Helpers =========="
echo 'alias k=kubectl' >> /home/ec2-user/.bashrc
echo 'alias tf=terraform' >> /home/ec2-user/.bashrc

mkdir -p /etc/bash_completion.d

kubectl completion bash > /etc/bash_completion.d/kubectl

chown ec2-user:ec2-user /home/ec2-user/.bashrc

echo "========== Versions =========="
java -version || true
docker --version || true
terraform version || true
helm version || true
kubectl version --client || true
eksctl version || true
k9s version || true

echo "========== Bootstrap Complete =========="