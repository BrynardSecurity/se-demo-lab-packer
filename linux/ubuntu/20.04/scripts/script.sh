# Apply updates and cleanup Apt cache
#
apt-get update; apt-get -y dist-upgrade
apt-get -y autoremove
apt-get -y cleanup
apt-get -y install docker.io 

# Disable swap - generally recommended for K8s, but otherwise enable it for other workloads
#
echo "Disabling Swap"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Reset the machine-id value. This has known to cause issues with DHCP
#
echo "Reset Machine-ID"
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Reset any existing cloud-init state
#
echo "Reset Cloud-Init"
cloud-init clean -s -l