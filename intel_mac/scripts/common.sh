#! /bin/bash

# kubelet의 적절한 동작을 위해서 swap을 사용하지 않는다.
swapoff -a && sed -i '/swap/s/^/#/' /etc/fstab

# Linux 노드의 iptables가 bridged traffic을 정확하게 확인하고 제어 할 수 있도록 br_netfilter 모듈을 load하고 관련된 네트워크 파라미터를 설정
lsmod | grep br_netfilter
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# kubeadm, kubelet, kubectl 설치
# . Update the apt package index and install packages needed to use the Kubernetes apt repository
sudo apt-get update -y
sudo apt-get install -y net-tools
sudo apt-get install -y openssh-server
sudo apt-get install -y apt-transport-https ca-certificates curl

# . Download the Google Cloud public signing key:
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# . Add the Kubernetes apt repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# . Update apt package index, install kubelet, kubeadm and kubectl, and pin their version
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "All the packages were Configured Successfully"


#Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

#set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#Install Docker Engine
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# add ccount to the docker group
sudo usermod -aG docker vagrant

# cgroupfs를 컨테이너 런타임과 kubelet 에 의해서 제어할 수 있도록 구성
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

#Configure containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

#restart containerd
sudo systemctl restart containerd

echo "ContainerD Runtime Configured Successfully"


