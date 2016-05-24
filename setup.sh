#!/bin/bash

echo ""
echo "Simple Syncthing Relay Setup Script by @theroyalstudent (Edwin A.)"
echo "============ [ GitHub Source: https://git.io/vr2xt ] ============="
echo "=================================================================="

echo ""
echo "Deleting old data and making sure no Syncthing Relay is running..."

killall relaysrv > /dev/null &> /dev/null
rm -rf relaysrv* /etc/relaysrv /home/relaysrv /usr/local/bin/relaysrv > /dev/null &> /dev/null
deluser relaysrv > /dev/null &> /dev/null

#Detecting apt-get/yum
whichaptget=`which apt-get`
whichyum=`which yum`
if [[ -e "$whichaptget" ]]; then
	OStype="apt-get"
	echo ""
	echo -n "Updating apt repositories..."
	apt-get update -y &>/dev/null
	echo "$(tput setaf 2)DONE$(tput sgr0)"
	echo ""
	echo "Installing packages: dtrx, sed, sudo, supervisor, wget if not installed yet."
	apt-get install sed sudo supervisor wget -y &>/dev/null
elif [[ -e "$whichyum" ]]; then
	OStype="yum"
	echo ""
	echo -n "Updating apt repositories..."
	yum update -y &>/dev/null
	echo "$(tput setaf 2)DONE$(tput sgr0)"
	echo ""
	echo "Installing packages: dtrx, sed, sudo, supervisor, wget if not installed yet."
	yum install sed sudo wget python-setuptools -y &>/dev/null
	easy_install supervisor &>/dev/null
	mkdir -p /etc/supervisor/conf.d
	echo_supervisord_conf > /etc/supervisor/supervisord.conf
	wget -q "https://raw.githubusercontent.com/theroyalstudent/setupSimpleSyncthingRelay/master/supervisord" -O "/etc/rc.d/init.d/supervisord"
	chmod 755 /etc/rc.d/init.d/supervisord
else
	echo "unsupported or unknown architecture"
	echo ""
	exit;
fi

echo ""
read -p "Please enter a relay name: " relayName

echo "You have entered '$relayName' as a relay name."

delimiter=' - '

if [ -z "$relayName" ]
then
	delimiter=''
fi

echo ""
echo "Thus, on the Syncthing Relay page at relays.syncthing.net, it will show as:"
echo "$relayName$delimiter$(wget ipinfo.io/city -qO -), $(wget ipinfo.io/country -qO -)"

#Detect architecture
if [ -n "$(uname -m | grep 64)" ]; then
	cpubits="linux-amd64"
	cpubitsname="for (64bit)..."
elif [ -n "$(uname -m | grep 86)" ]; then
	cpubits="linux-386"
	cpubitsname="for (32bit)..."
elif [ -n "$(uname -m | grep armv*)" ]; then
	cpubits="linux-arm"
	cpubitsname="for (ARM)..."
else
	echo "unsupported or unknown architecture"
	echo ""
	exit;
fi

echo ""
echo "Downloading latest release of the relaysrv daemon $cpubitsname"
cd
wget $(wget https://api.github.com/repos/syncthing/relaysrv/releases/latest -qO - | grep 'browser_' | grep $cpubits | cut -d\" -f4) &>/dev/null

echo ""
echo -n "Extracting the relaysrv daemon..."
dtrx relaysrv-linux*
echo "	$(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Moving the relaysrv daemon to /usr/local/bin..."
cd relaysrv-linux*
mv relaysrv /usr/local/bin
echo "  $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Clearing up the remains of the relaysrv daemon."
cd
rm -rf relaysrv-linux*
echo "  $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo "Adding a user for relaysrv, called relaysrv."
adduser relaysrv --gecos '' --disabled-password
mkdir /etc/relaysrv
chown relaysrv /etc/relaysrv

echo ""
echo -n "Copying Syncthing Relay supervisord configuration to the respective folder..."
wget -q "https://raw.githubusercontent.com/theroyalstudent/setupSimpleSyncthingRelay/master/syncthingRelay.conf" -O "/etc/supervisor/conf.d/syncthingRelay.conf"

echo ""
echo "Setting geolocation of the Syncthing relay."
sed -i s/RELAYNAME/"$relayName$delimiter$(wget ipinfo.io/city -qO -), $(wget ipinfo.io/country -qO -)"/ /etc/supervisor/conf.d/syncthingRelay.conf

echo ""
echo "Restarting supervisord..."
if [[ -e "/etc/rc.d/init.d/supervisord" ]]; then
	service supervisord restart
else
	service supervisor restart
fi

echo ""
echo "And you should be up and running! (http://relays.syncthing.net)"
echo "If this script worked, feel free to give my script a star!"
echo "Exiting."
echo ""
exit 0
