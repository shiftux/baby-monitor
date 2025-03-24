# Setup the automatic switching between access point and wifi client
The switch is based on the availability of the WiFi which is defined in wpa_supplicant file. If a known WiFi is found the RPi will work in client mode. Elese the RPi will enable an access point via which the user can enter a new WiFi connection, which will be used in client mode after a restart.
Inspiration from: [link](https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/157-raspberry-pi-auto-wifi-hotspot-switch-internet)

### Install & configure prerequisits
First set WiFi locales:
```
sudo raspi-config
```
```
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y hostapd dnsmasq
```
For those packages the automatic startup needs to be disabled and by default hostapd is masked so needs to be unmasked.
```
sudo systemctl unmask hostapd
sudo systemctl disable hostapd
sudo systemctl disable dnsmasq
```

### config files
`/etc/hostapd/hostapd.conf`

```
#2.4GHz setup wifi 80211 b,g,n
interface=wlan0
driver=nl80211
ssid=<<< enter SSID >>>
hw_mode=g
channel=8
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=<<< enter passphrase >>>
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP TKIP
rsn_pairwise=CCMP

#80211n - Change CH to your WiFi country code
country_code=CH
ieee80211n=1
ieee80211d=1
```

_________________

`/etc/default/hostapd`
change
```
#DAEMON_CONF=""
```
to
```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```
make sure that `Check the DAEMON_OPTS=""` is preceded by a `#` (default it is)

_________________

`/etc/dnsmasq.conf`

```
#AutoHotspot config
interface=wlan0
bind-dynamic 
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.50.150,192.168.50.200,12h
```

_________________

`/etc/network/interfaces`
should not contain more than

```
# interfaces(5) file used by ifup(8) and ifdown(8)
# Please note that this file is written to be used with dhcpcd
# For static IP, consult /etc/dhcpcd.conf and 'man dhcpcd.conf'
# Include files from /etc/network/interfaces.d:
source-directory /etc/network/interfaces.d
```

_________________

`/etc/sysctl.conf`
make sure the following line is active (uncommented). This enables to share the ethernet connection over wifi

```
for IPv4
net.ipv4.ip_forward=1
```


_________________

`/etc/dhcpcd.conf`
at the bottom of the file enter the line

```
nohook wpa_supplicant
```


### autohotspot service file

`/etc/systemd/system/autohotspot.service`

```
[Unit]
Description=Automatically generates an internet Hotspot when a valid ssid is not in range
After=multi-user.target
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/autohotspot
[Install]
WantedBy=multi-user.target
```
then enable it with: 
```
sudo systemctl enable autohotspot.service
```

### autohotspot script
`/usr/bin/autohotspot`

```

```

then make it executable
sudo chmod +x /usr/bin/autohotspot
