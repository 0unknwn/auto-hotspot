#!/bin/bash
device=wlan0
timeoutAP=2m
timeoutDiscon=10
# https://raspberrypi.stackexchange.com/questions/100195

### Check if run as root ############################
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 
	echo "Try \"sudo $0 --install\""	
	exit 1
fi

### INSTALL SECTION #################################
if [[ "$1" =~ "install" ]]; then

	## Change to systemd-networkd
	systemctl mask networking.service dhcpcd.service
	sudo mv /etc/network/interfaces /etc/network/interfaces~
	sed -i '1i resolvconf=NO' /etc/resolvconf.conf

	systemctl enable systemd-networkd.service systemd-resolved.service
	ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

	## Install configuration files for systemd-networkd
	cat > /etc/systemd/network/08-CLI.network <<-EOF
		[Match]
		Name=$device
		[Network]
		DHCP=yes
	EOF
		
	cat > /etc/systemd/network/12-AP.network <<-EOF
		[Match]
		Name=$device
		[Network]
		Address=192.168.4.1/24
		IPForward=yes
		DHCPServer=yes
		[DHCPServer]
		DNS=84.200.69.80 84.200.70.40
	EOF

	## Install systemd-service to configure interface automatically
	if [ ! -f /etc/systemd/system/wpa_cli@${device}.service ] ; then
		cat > /etc/systemd/system/wpa_cli@${device}.service <<-EOF
			[Unit]
			Description=Wpa_cli to Automatically Create an Accesspoint if no Client Connection is Available
			After=network-online.target wpa_supplicant@${device}.service sys-subsystem-net-devices-%i.device
			BindsTo=wpa_supplicant@${device}.service

			[Service]
			ExecStart=/usr/sbin/wpa_cli -i %I -a $(pwd)/$0
			Restart=on-failure
			RestartSec=1

			[Install]
			WantedBy=multi-user.target
		EOF
	else
	  echo "wpa_cli@$device.service is already installed"
	fi

	systemctl daemon-reload
	systemctl enable --now wpa_cli@${device}.service
	exit 0
fi

### END INSTALL SECTION ################################


### FUNCTIONS ##########################################

# Disable client configuration by moving .network file
# and restarting systemd-networkd
configure_ap () {
	if [ -e /etc/systemd/network/08-CLI.network ]; then
		mv /etc/systemd/network/08-CLI.network /etc/systemd/network/08-CLI.network~
		systemctl restart systemd-networkd
	fi
}

# Enable client configuration by moving .network file
# and restarting systemd-networkd
configure_client () {
	if [ -e /etc/systemd/network/08-CLI.network~ ]; then
		mv /etc/systemd/network/08-CLI.network~ /etc/systemd/network/08-CLI.network
		systemctl restart systemd-networkd
	fi
}

# Reocnfigure wpa_supplicant to search for networks again 
# after a given time, if nobody is connected to the ap
reconfigure_wpa_supplicant () {
	sleep "$1"
	if [ "$(iw $device station dump)" = "" ]; then
		wpa_cli -i $device reconfigure
	fi
}

### PROCEDURE ###########################################

case "$2" in

	# Configure accesspoint if enabled
	AP-ENABLED)
		configure_ap
		reconfigure_wpa_supplicant "$timeoutAP" &
		;;

	CONNECTED)
		if iw $device info | grep -q "type managed"; then
			configure_client
		fi
		;;

	# Reconfigure wpa_supplicant to search for networks, 
	# if nobody is connected to the ap
	AP-STA-DISCONNECTED)
		reconfigure_wpa_supplicant "$timeoutDiscon"
		;;
esac
