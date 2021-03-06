#!/bin/sh

# update system
yum -y update
yum -y install epel-release
yum -y install git libvirt qemu-kvm virt-install virt-top libguestfs-tools bridge-utils
yum install socat -y
yum install -y conntrack
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vagrant
systemctl start docker
yum -y install wget
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
mv minikube-linux-amd64 /usr/bin/minikube
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl  /usr/bin/
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# add user jenkins
useradd jenkins
usermod -aG docker jenkins
usermod -aG wheel jenkins
sudo echo "jenkins        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/jenkins
su jenkins -c "ssh-keygen -q -f ~/.ssh/id_rsa -N ''"

# start minikube with user jenkins
systemctl enable docker.service
su - jenkins -c "minikube start --kubernetes-version=1.20.0 --driver=none"

# Enable unsecure connections to the registry
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["192.168.100.10:5000"]
}
EOF
systemctl restart docker

# Enable local dns on each server
echo -e "192.168.100.10 jenkins" >> /etc/hosts
echo -e "192.168.100.11 staging" >> /etc/hosts
echo -e "192.168.100.12 production" >> /etc/hosts

yum install bash-completion -y
echo 'source <(kubectl completion bash)' >> ~jenkins/.bashrc
echo 'alias k=kubectl' >> ~jenkins/.bashrc
echo 'complete -F __start_kubectl k' >> ~jenkins/.bashrc
echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"
