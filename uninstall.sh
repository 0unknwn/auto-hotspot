interfaceWifi=wlan0
interfaceWired=eth0

### Check if run as root ############################
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	echo "Try \"sudo $0\""	
	exit 1
fi
	
systemctl disable systemd-networkd.service systemd-resolved.service
apt-mark unhold ifupdown dhcpcd5 isc-dhcp-client isc-dhcp-common rsyslog raspberrypi-net-mods openresolv avahi-daemon libnss-mdns
rm /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
apt install -y ifupdown dhcpcd5 isc-dhcp-client rsyslog avahi-daemon
apt purge --autoremove -y libnss-resolve

# Remove the wpa_cli script an disable wpa_cli.service
rm /usr/local/sbin/auto-hotspot
systemctl disable wpa_cli@wlan0.service #If your device is named »wlan0«

# Remove all config files
rm /etc/systemd/network/04-${interfaceWired}.network
rm /etc/systemd/network/08-${interfaceWifi}-CLI.network
rm /etc/systemd/network/12-${interfaceWifi}-AP.network
rm /etc/systemd/network/12-${interfaceWifi}-AP.network

echo "Uninstalled auto-hotspot"
echo "Reboot now!"

exit 0
