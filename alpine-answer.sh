KEYMAPOPTS=none
HOSTNAMEOPTS=${hostname}
DEVDOPTS=udev

INTERFACESOPTS=none

TIMEZONEOPTS=none
PROXYOPTS=none

# Add first mirror (CDN)
APKREPOSOPTS="-1"

USEROPTS="-a -u -g audio,video,netdev vagrant"
USERSSHKEY="${trimspace(file("${path.root}/keys/vagrant.pub"))}"

SSHDOPTS="openssh"
ROOTSSHKEY="${trimspace(file("${path.root}/keys/vagrant.pub"))}"

NTPOPTS="openntpd"

DISKOPTS="-v -k lts -m sys /dev/vda"
