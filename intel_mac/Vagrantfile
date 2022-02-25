NUM_WORKER=2
IP_NW="192.168.137."
IP_START=100

Vagrant.configure("2") do |config|
    config.vm.provision "shell", inline: <<-SHELL
        apt-get update -y
        # echo "192.168.137.100 master" >> /etc/hosts
        # echo "192.168.137.101 worker1" >> /etc/hosts
        # echo "192.168.137.102 worker2" >> /etc/hosts
    SHELL
    config.vm.box = "ubuntu/bionic64"
    config.vm.box_check_update = true

    config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.network "private_network", ip: IP_NW + "#{IP_START}"
      master.vm.provider "virtualbox" do |vb|
          vb.memory = 2048
          vb.cpus = 2
          vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end
      master.vm.provision "shell", path: "scripts/common.sh"
      master.vm.provision "shell", path: "scripts/master.sh"
    end

    (1..NUM_WORKER).each do |i|
      config.vm.define "worker#{i}" do |node|
        node.vm.hostname = "worker#{i}"
        node.vm.network "private_network", ip: IP_NW + "#{IP_START + i}"
        node.vm.provider "virtualbox" do |vb|
            vb.memory = 1024
            vb.cpus = 1
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        end
        node.vm.provision "shell", path: "scripts/common.sh"
        node.vm.provision "shell", path: "scripts/worker.sh"
      end
    end
  end