#! /bin/bash

RUNNER=vagrant
RUNNER_HOME=$(eval echo "~$RUNNER")

/bin/bash /vagrant/configs/join.sh -v

sudo -i -u $RUNNER bash << EOF
mkdir -p $RUNNER_HOME/.kube
sudo cp -i /vagrant/configs/config $RUNNER_HOME/.kube/
sudo chown $(su - $RUNNER -c "id -u"):$(su - $RUNNER -c "id -g") $RUNNER_HOME/.kube/config
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker-new
EOF

# settings for auto completion
echo 'source <(kubectl completion bash)' >> $RUNNER_HOME/.bashrc
echo 'alias k=kubectl' >> $RUNNER_HOME/.bashrc
echo 'complete -F __start_kubectl k' >> $RUNNER_HOME/.bashrc

sudo systemctl restart systemd-resolved
sudo swapoff -a && sudo systemctl daemon-reload && sudo systemctl restart kubelet

