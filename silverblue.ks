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
%{ for key in compact(split("\n", file("${path.root}/keys/vagrant.pub"))) ~}
sshkey --username=vagrant ${jsonencode(key)}
%{ endfor ~}
ostreesetup --osname="fedora-silverblue" --remote="fedora" --url="file:///ostree/repo" --ref="fedora/${version}/x86_64/silverblue" --nogpg
reboot

%post
systemctl set-default graphical.target

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
echo "vagrant ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

sed -i -e "s/.*PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
sed -i -e "s/.*PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config

fstrim -av --quiet-unsupported
%end
