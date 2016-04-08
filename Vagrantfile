# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.network :public_network, type: "dhcp"
  config.vm.synced_folder "./", "/vagrant", id: "vagrant-root",
    owner: "vagrant",
    group: "www-data",
    mount_options: ["dmode=775,fmode=664"]

  # Provision docker
  config.vm.provision "docker" do |d|
    d.pull_images "mysql:5.6"
    d.build_image "/vagrant/containers/web", args: "-t xibo-cms:develop"
    d.build_image "/vagrant/containers/xmr", args: "-t xibo-xmr:develop"
    d.run "cms-db",
      image: "mysql:5.6",
      args: "-v /vagrant/shared/db:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root"
    d.run "cms-xmr",
      image: "xibo-xmr:develop",
      args: "-p 9505:9505"
    d.run "cms-web",
      image: "xibo-cms:develop",
      args: "-p 8080:80 -e XIBO_DEV_MODE=true -v /vagrant/shared/web:/var/www/xibo -v /vagrant/shared/backup:/var/www/backup --link cms-db:mysql --link cms-xmr:50000"
  end

  # Run a shell provisioner to restart the docker cms-web container (to map the shared folder correctly)
  config.vm.provision "shell",
    inline: "docker restart cms-web",
    run: "always"

  config.vm.provision "shell",
    inline: "/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'",
    run: "always"
end
