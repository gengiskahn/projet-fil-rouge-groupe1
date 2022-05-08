#!/bin/sh

# update system
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum update -y
yum -y install epel-release 
yum install -y sshpass
yum -y install wget
yum install -y git
yum upgrade -y

# allow ssh password
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vagrant
# allow http connections to registry
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["jenkins:5000"]
}
EOF


# Start Docker
systemctl enable docker
systemctl start docker

# add user jenkins
useradd jenkins
usermod -aG docker jenkins
usermod -aG wheel jenkins
sudo echo "jenkins        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/jenkins
su jenkins -c "ssh-keygen -q -f ~/.ssh/id_rsa -N ''"

# Enable local dns on each server
echo -e "192.168.100.10 jenkins" >> /etc/hosts
echo -e "192.168.100.11 staging" >> /etc/hosts
echo -e "192.168.100.12 production" >> /etc/hosts

# Install Minikube
sudo cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y kubectl

yum install bash-completion -y
echo 'source <(kubectl completion bash)' >> ~vagrant/.bashrc
echo 'alias k=kubectl' >> ~vagrant/.bashrc
echo 'complete -F __start_kubectl k' >> ~vagrant/.bashrc
echo "For this Stack, you will use $(ip -f inet addr show eth1 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"