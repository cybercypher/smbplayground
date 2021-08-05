#!/bin/bash -ex
#quick and dirty script to setup a samba4 active directory domain controller

if ! [ $(id -u) = 0 ]; then
   echo "I am not root!"
   exit 1
fi

DCHOSTNAME=$1
DCINTERFACE=$2
DCSTATICIP=$3
DCIPNETMASK=$4 
DCDOMAIN=$5
sudo hostnamectl set-hostname ${DCHOSTNAME}
sudo hostname ${DCHOSTNAME}
echo "${DCSTATICIP} ${DCHOSTNAME}.${DCDOMAIN} ${DCHOSTNAME}" >> /etc/hosts

sudo apt update -y && sudo upgrade -y
sudo apt-get install -y acl attr samba samba-dsdb-modules samba-vfs-modules winbind libpam-winbind libnss-winbind libpam-krb5 krb5-config krb5-user dnsutils chrony net-tools


sudo pkill -9 samba
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.orig
sudo mv /etc/krb5.conf /etc/krb5.conf.orig

sudo samba-tool domain provision --use-rfc2307 --interactive
sudo cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

## ADD samba interface line
sed '/.*rfc2307.*/a \1i bind interfaces only = yes\ninterfaces = lo ${DCINTERFACE}' /etc/samba/smb.conf >> /etc/samba/smb.conf.interfaces
cp /etc/samba/smb.conf.interfaces /etc/samba/smb.conf


sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo unlink /etc/resolv.conf
sudo nano /etc/resolv.conf

echo "nameserver ${DCSTATICIP}" >> /etc/resolv.conf
echo "search ${DCDOMAIN}" >> /etc/resolv.conf

echo "allow ${DCIPNETMASK}" >> /etc/chrony/chrony.conf
echo "ntpsigndsocket /var/lib/samba/ntp_signd" >> /etc/chrony/chrony.conf

sudo pkill -9 samba
sudo systemctl mask smbd nmbd winbind
sudo systemctl disable smbd nmbd winbind
sudo systemctl stop smbd nmbd winbind
sudo systemctl unmask samba-ad-dc
sudo systemctl start samba-ad-dc
sudo systemctl enable samba-ad-dc

echo "Dont forget to run kinit Administrator"
