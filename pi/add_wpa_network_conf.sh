#!/bin/bash
############# input handling and usage #############
usage(){
    printf "usage: add_wpa_network_conf [-s <SSID> (required)] [-p <WPA_password> (required)]\n\
    This script will add a wireless network configuration to /etc/wpa_supplicant/wpa_supplicant.conf\n\
    Use -h to print this help message\n"
    exit 1
}

while getopts "s:p:h" option        # the options with colons after them expect an input arg, h without colon does not
do
    case $option in
        s)
                SSID=${OPTARG};;
        p)
                PW=${OPTARG};;
        h)
                usage
                exit;;
        (*)
                usage
                exit;;
    esac
done

############# WPA manipulation #############
# make sure all required options have been passed
if [ -z "${SSID}" ] || [ -z "${PW}" ]; then
    echo "error: missing arguments"
    usage
fi

# masking the private key
wpa_passphrase "${SSID}" "${PW}" > tmp_network.cfg
sed '/#psk/d' -i tmp_network.cfg

# adding the configuration to the wpa_supplicatns file
sudo sh -c 'cat tmp_network.cfg >> /etc/wpa_supplicant/wpa_supplicant.conf'

# cleanup
rm -rf tmp_network.cfg
unset SSID PW
