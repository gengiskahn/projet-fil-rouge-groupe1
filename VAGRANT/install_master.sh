#!/bin/bash

# update system
yum update -y
yum -y install epel-release 
yum install -y sshpass
yum install -y wget
yum install -y git
yum upgrade -y

# install jenkins
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# Add required dependencies for the jenkins package
yum install java-11-openjdk -y 
yum install jenkins -y

# Start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vagrant
usermod -aG docker jenkins

# Start Docker
systemctl enable docker
systemctl start docker


# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Enable unsecure connections to the registry
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["192.168.100.10:5000"]
}
EOF

systemctl restart docker

# Install Docker Registry ande UI
docker run -d --restart always -p 5000:5000 -e REGISTRY_STORAGE_DELETE_ENABLED=true --name registry registry:2

cat <<EOF > docker-compose.yml
version: "2"
services:
  app:
    image: jc21/registry-ui
    ports:
      - 80:80
    environment:
      - REGISTRY_HOST=192.168.100.10:5000
      - REGISTRY_SSL=false
      - REGISTRY_DOMAIN=192.168.100.10:5000
      - REGISTRY_STORAGE_DELETE_ENABLED=true
      - REGISTRY_USER=
      - REGISTRY_PASS=
    restart: on-failure
EOF

/usr/local/bin/docker-compose up -d


# install ansible
yum install -y python3
curl -sS https://bootstrap.pypa.io/pip/3.6/get-pip.py | sudo python3
/usr/local/bin/pip3 install ansible

# Enable local dns on each server
echo -e "192.168.100.10 jenkins" >> /etc/hosts
echo -e "192.168.100.11 staging" >> /etc/hosts
echo -e "192.168.100.12 production" >> /etc/hosts

# update user jenkins

mkdir /var/lib/jenkins/.ssh
ssh-keygen -q -f /var/lib/jenkins/.ssh/id_rsa -N ''
echo 'Host * ' > /var/lib/jenkins/.ssh/config
echo '    StrictHostKeyChecking no' >> /var/lib/jenkins/.ssh/config
chown -R jenkins: /var/lib/jenkins/.ssh
chmod 600 /var/lib/jenkins/.ssh/*
systemctl restart jenkins

# update ssh for jenkins on remotes

cat /var/lib/jenkins/.ssh/id_rsa.pub |  sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@staging  "sudo su -c \"cat >>  ~jenkins/.ssh/authorized_keys\""
cat /var/lib/jenkins/.ssh/id_rsa.pub |  sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@production  "sudo su -c \"cat >>  ~jenkins/.ssh/authorized_keys\""

#echo "For this Stack, you will use $(ip -f inet addr show enp0s8 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"