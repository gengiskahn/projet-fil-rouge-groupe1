#!/bin/bash

# update system
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
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
cat <<EOF > /etc/docker/daemon.json
{
  "insecure-registries" : ["192.168.100.10"]
}
EOF

# Start Docker
systemctl enable docker
systemctl start docker

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Docker Registry ande UI
cat <<EOF > docker-compose.yml
version: "2"
services:
  registry:
    image: registry:2
    environment:
      - REGISTRY_HTTP_SECRET=o43g2kjgn2iuhv2k4jn2f23f290qfghsdg
      - REGISTRY_STORAGE_DELETE_ENABLED=
    volumes:
      - ./registry-data:/var/lib/registry
  ui:
    image: jc21/registry-ui
    environment:
      - NODE_ENV=production
      - REGISTRY_HOST=registry:5000
      - REGISTRY_SSL=
      - REGISTRY_DOMAIN=
      - REGISTRY_STORAGE_DELETE_ENABLED=
    links:
      - registry
    restart: on-failure
  proxy:
    image: jc21/registry-ui-proxy
    ports:
      - 80:80
    depends_on:
      - ui
      - registry
    links:
      - ui
      - registry
    restart: on-failure
EOF
docker-compose up -d


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

# update ssh for jenkins on remotes
# Declare function to ensure ssh is ready
function waitforssh {
    sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@$1 echo ssh is up on $1
    while test $? -gt 0
    do
        echo -e "SSH server not started on $1 host. Trying again later in 5 seconds..."
		sleep 5 
        sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@$1 echo ssh is up on $1
    done
}
#waitforssh staging
cat /var/lib/jenkins/.ssh/id_rsa.pub |  sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@staging  "sudo su -c \"cat >>  ~jenkins/.ssh/authorized_keys\""
#waitforssh production
cat /var/lib/jenkins/.ssh/id_rsa.pub |  sshpass -p vagrant ssh -o StrictHostKeyChecking=no vagrant@production  "sudo su -c \"cat >>  ~jenkins/.ssh/authorized_keys\""

#echo "For this Stack, you will use $(ip -f inet addr show eth1 | sed -En -e 's/.*inet ([0-9.]+).*/\1/p') IP Address"