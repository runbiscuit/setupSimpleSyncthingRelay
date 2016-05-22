#!/bin/bash

echo "Simple Syncthing Relay Setup Script by @theroyalstudent (Edwin A.)"
echo "============ [ GitHub Source: https://git.io/vr2xt ] ============="
echo "=================================================================="

echo ""
echo "Deleting old data and making sure no Syncthing Relay is running..."

killall relaysrv > /dev/null &> /dev/null
rm -rf relaysrv* /etc/relaysrv /home/relaysrv /usr/local/bin/relaysrv > /dev/null &> /dev/null
deluser relaysrv > /dev/null &> /dev/null

echo ""
echo "Please enter a relay name."
read relayName

echo "You have entered '$relayName' as a relay name."

delimiter=' - '

if [ -z "$relayName" ]
then
	delimiter=''
fi

echo ""
echo "Thus, on the Syncthing Relay page at relays.syncthing.net, it will show as:"
echo "$relayName$delimiter$(wget ipinfo.io/city -qO -), $(wget ipinfo.io/country -qO -)"

echo ""
echo "Updating apt repositories..."
apt-get update > /dev/null

echo ""
echo "Installing packages: dtrx, sed, supervisor, wget if not installed yet."
apt-get install dtrx sed supervisor wget -y > /dev/null

echo ""
echo "Downloading latest release of the relaysrv daemon..."
wget $(wget https://api.github.com/repos/syncthing/relaysrv/releases/latest -qO - | grep 'browser_' | grep 'linux-amd64' | cut -d\" -f4)

echo ""
echo "Extracting the relaysrv daemon..."
dtrx relaysrv-linux-amd64.tar.gz

echo ""
echo "Moving the relaysrv daemon to /usr/local/bin..."
mv relaysrv-linux-amd64/relaysrv /usr/local/bin

echo ""
echo "Clearing up the remains of the relaysrv daemon."
rm -rf relaysrv-linux-amd64*

echo ""
echo "Adding a user for relaysrv, called relaysrv."
adduser relaysrv --gecos '' --disabled-password
mkdir /etc/relaysrv
chown relaysrv /etc/relaysrv

echo ""
echo "Copying Syncthing Relay supervisord configuration to the respective folder..."
cp syncthingRelay.conf /etc/supervisor/conf.d/syncthingRelay.conf

echo ""
echo "Setting geolocation of the Syncthing relay."
sed -i s/RELAYNAME/"$relayName$delimiter$(wget ipinfo.io/city -qO -), $(wget ipinfo.io/country -qO -)"/ /etc/supervisor/conf.d/syncthingRelay.conf

echo ""
echo "Restarting supervisord..."
sudo service supervisor restart

echo "And you should be up and running!"
echo "If this script worked, feel free to give my script a star!"
echo "Exiting."
