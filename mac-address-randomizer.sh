#!/bin/bash

if [ $(id -u) -ne 0 ]; then
	echo "Run this script as root (sudo)"
	exit 1
fi

echo "------------------------------"
echo "Mercury MAC Address Randomizer"
echo "------------------------------"

state=$(cat /sys/class/net/wlan0/operstate)

mac_dev=$(cat /sys/firmware/vpd/ro/wifi_mac0)
echo "Device MAC: ${mac_dev}"

get_mac_cur() {
	cat /sys/class/net/wlan0/address
}
mac_cur="$(get_mac_cur)"
echo "Current MAC: ${mac_cur}"

gen_mac() {
	echo "$(echo "${mac_dev}" | head -c $((-3 * $1 + 17))):$(hexdump -e '1/1 "%02x:"' -v -n $1 /dev/urandom)" | head -c 17
}

echo "Choose an action"
echo "3 - randomize last 3 bytes"
echo "5 - randomize last 5 bytes"
echo "c - custom MAC address"
if [ "${mac_cur}" != "${mac_dev}" ]; then
	echo "r - reset MAC address"
fi
echo "e - cancel and exit"
read -p "> " action

case "${action}" in
	3)
		mac_new="$(gen_mac 3)"
		;;
	5)
		mac_new="$(gen_mac 5)"
		;;
	c | C)
		read -p "Enter new MAC address: " mac_new
		;;
	r | R)
		mac_new="${mac_dev}"
		;;
	e | E)
		echo "Cancelled"
		exit
		;;
	*)
		echo "Invalid action"
		exit 1
		;;
esac

echo -n "Setting new MAC (${mac_new})... "
if [ "${state}" == "up" ]; then
	ip link set dev wlan0 down
fi
ip link set dev wlan0 address "${mac_new}"
if [ "${state}" == "up" ]; then
	ip link set dev wlan0 up
fi

mac_new_real=$(get_mac_cur)
if [ "${mac_new_real}" == "${mac_new}" ]; then
	echo "Done"
elif [ "${mac_new_real}" == "${mac_cur}" ]; then
	echo "Failed to change MAC address"
else
	echo "Something wacky happened"
fi
echo "Current MAC: ${mac_new_real}"
