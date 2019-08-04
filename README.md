# autoAccessPoint
This script is intended for the Raspeberry Pi. It will automatically create a hotspot, if there is no known wifi nearby. 
Therefore it will use `systemd-networkd`, `wpa_supplicant` and `wpa_cli`.
If no device is connected for a while to the hotspot it will search for neworks again.

You need to have a wpa_supllicant@device.service file similiar to this.

```
country=FR                                                                        
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev                           
update_config=1                                                                   
ap_scan=1

### your network(s) ###    
network={                                                                         
    priority=10       # add a priority higher then 0 to any network                                                         
    ssid="yourWifi"   # except the access point's one!
    psk="passphrase"                                                 
} 

### your hotspot ###                                                                                  
network={                                                                        
    ssid="accesspoint"    # your access point's name                                                            
    mode=2                                                                       
    key_mgmt=WPA-PSK                                                             
    psk="passphrase"      # your access point's password                                    
    frequency=2462                                                               
}
```

After having installed the script (see below) you can start a hotspot manually by running `auto-hotspot --start-ap` 
and stop it with `--stop-ap`.

If there is a wired network connection the Pi will work as a repeater

How it works is also discussed here: 
https://raspberrypi.stackexchange.com/questions/100195


## Install

```
wget https://github.com/0unknwn/autoAccessPoint/blob/master/auto-hotspot
chmod +x auto-hotspot install.sh
sudo ./install.sh
```

