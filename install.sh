#!/bin/bash
interfaceWifi=wlan0
interfaceWired=eth0
ipAddress=192.168.4.1/24

### Check if run as root ############################
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	echo "Try \"sudo $0 $*\""	
	exit 1
fi

### INSTALL SECTION #################################
	
## Change over to systemd-networkd
systemctl mask networking.service dhcpcd.service
mv /etc/network/interfaces /etc/network/interfaces~
sed -i '1i resolvconf=NO' /etc/resolvconf.conf
systemctl enable systemd-networkd.service systemd-resolved.service
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

## Install configuration files for systemd-networkd
cat > /etc/systemd/network/04-${interfaceWired}.network <<-EOF
	[Match]
	Name=$interfaceWired
	[Network]
	DHCP=yes
	IPForward=yes
	EOF

cat > /etc/systemd/network/08-${interfaceWifi}-CLI.network <<-EOF
	[Match]
	Name=$interfaceWifi
	[Network]
	DHCP=yes
EOF
		
cat > /etc/systemd/network/12-${interfaceWifi}-AP.network <<-EOF
	[Match]
	Name=$interfaceWifi
	[Network]
	Address=$ipAddress
	DHCPServer=yes
	[DHCPServer]
	DNS=84.200.69.80 84.200.70.40
EOF

cp $(pwd)/auto-hotspot /usr/local/sbin/
chmod +x /usr/local/sbin/auto-hotspot

## Install systemd-service to configure interface automatically
if [ ! -f /etc/systemd/system/wpa_cli@${interfaceWifi}.service ] ; then
	cat > /etc/systemd/system/wpa_cli@${interfaceWifi}.service <<-EOF
		[Unit]
		Description=Wpa_cli to Automatically Create an Accesspoint if no Client Connection is Available
		After=wpa_supplicant@%i.service
		BindsTo=wpa_supplicant@%i.service
		[Service]
		ExecStart=/sbin/wpa_cli -i %I -a /usr/local/sbin/auto-hotspot
		Restart=on-failure
		RestartSec=1
		[Install]
		WantedBy=multi-user.target
	EOF
else
  echo "wpa_cli@$interfaceWifi.service is already installed"
fi

systemctl daemon-reload
systemctl enable wpa_cli@${interfaceWifi}.service
echo "Reboot now!"
exit 0
