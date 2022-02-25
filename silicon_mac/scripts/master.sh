#! /bin/bash

sudo hostnamectl set-hostname master

MASTER_IP=`ifconfig |grep 192.168.137|awk '{print $2}'`
NODENAME=$(hostname -s)
POD_CIDR="10.100.0.0/16"

RUNNER=vagrant
RUNNER_HOME=$(eval echo "~$RUNNER")

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init --apiserver-advertise-address=$MASTER_IP  --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name $NODENAME 

# configuration setup for normal user (RUNNER)
mkdir -p $RUNNER_HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $RUNNER_HOME/.kube/config
sudo chown $(su - $RUNNER -c "id -u"):$(su - $RUNNER -c "id -g") $RUNNER_HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> $HOME/.bashrc

# settings for auto completion
echo 'source <(kubectl completion bash)' >> $RUNNER_HOME/.bashrc
echo 'alias k=kubectl' >> $RUNNER_HOME/.bashrc
echo 'complete -F __start_kubectl k' >> $RUNNER_HOME/.bashrc

echo 'source <(kubectl completion bash)' >> $HOME/.bashrc
echo 'alias k=kubectl' >> $HOME/.bashrc
echo 'complete -F __start_kubectl k' >> $HOME/.bashrc

# Save Configs to shared /Vagrant location
# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.
config_path="/vagrant/configs"

if [ -d $config_path ]; then
   rm -f $config_path/*
else
   mkdir -p /vagrant/configs
fi


cp -i /etc/kubernetes/admin.conf /vagrant/configs/config
touch /vagrant/configs/join.sh
chmod +x /vagrant/configs/join.sh       

# Generete kubeadm join command
kubeadm token create --print-join-command > /vagrant/configs/join.sh

# Install Calico Network Plugin
curl https://docs.projectcalico.org/manifests/calico.yaml -O

kubectl apply -f calico.yaml
rm -f calico.yaml
