# autoAccessPoint
This script is intended for the Raspeberry Pi. It will automatically create a hotspot, if there is no known wifi nearby. 
Therefore it will use `systemd-networkd`, `wpa_supplicant` and `wpa_cli`.

After having installed the script (see below) you can start a hotspot manually by running `auto-hotspot --start-ap` 
and stop it with `--stop-ap`.

If there is a wired network connection the Pi will work as a repeater

How it works is also discussed here: 
https://raspberrypi.stackexchange.com/questions/100195


## Install

```wget https://github.com/0unknwn/autoAccessPoint/blob/master/autoAP.sh
chmod +x auto-hotspot
sudo mv auto-hotspot /usr/local/bin
sudo auto-hotspot --install
```


