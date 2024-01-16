selinux --enforcing
firewall --enabled --service=mdns
services --enabled=sshd,NetworkManager,chronyd
network --bootproto=dhcp --device=link --activate --hostname=${hostname}
rootpw --plaintext vagrant
zerombr
bootloader --location=mbr
firstboot --disable
autopart
user --name=vagrant --groups=wheel --password=vagrant --plaintext
sshkey --username=vagrant "${trimspace(file("${path.root}/keys/vagrant.pub"))}"
reboot

repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch

%packages
@core
@standard
@hardware-support
@base-x
@gnome-desktop
@guest-desktop-agents
%end

%post
systemctl set-default graphical.target

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
echo "vagrant ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

sed -i -e "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i -e "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config

dnf clean all -y
%end
