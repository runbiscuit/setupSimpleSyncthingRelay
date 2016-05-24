#!/bin/bash

echo ""
echo "=================================================================="
echo "Simple Syncthing Relay Setup Script by @theroyalstudent (Edwin A.)"
echo "============ [ GitHub Source: https://git.io/vr2xt ] ============="
echo "=================================================================="

echo ""
echo "Deleting old data and making sure no Syncthing Relay is running..."

killall relaysrv > /dev/null &> /dev/null
rm -rf relaysrv* /etc/relaysrv /home/relaysrv /usr/local/bin/relaysrv > /dev/null &> /dev/null
deluser relaysrv > /dev/null &> /dev/null

# input relay name

echo ""
read -p "Please enter a relay name: " relayName

echo "You have entered '$relayName' as a relay name."

delimiter=' - '

if [ -z "$relayName" ]
then
	delimiter=''
fi

# autodetect/input server geolocation

serverIPgeolocation="$(wget ipinfo.io/city -qO -), $(wget ipinfo.io/country -qO -)"

echo ""
echo "Your server IP geolocation is $serverIPgeolocation"
read -p "Is this correct? [Y/n]: " serverIPverification

if [[ "$serverIPverification" == [Nn] ]]
then
	read -p "Enter correct/preferred name: " serverIPgeolocation
elif [[ "$serverIPverification" == [Yy] ]] || [[ -z "$serverIPverification" ]]
then
	echo "Nice, proceeding."
else
	echo "User has not entered a valid response, unable to determine if autodetected location is accurate."
	echo "Exiting."
	exit 0;
fi

# inform user on relay name

displayName="$relayName$delimiter$serverIPgeolocation"

echo ""
echo "Thus, on the Syncthing Relay page at relays.syncthing.net, it will show as:"
echo $displayName

# ask user whether he is behind a NAT

echo ""
read -p "Are you behind a NAT or a firewall? [N/y]: " nat

if [[ "$nat" == [Yy] ]]
then
	echo ""
	echo "On commercial NAT VPS services like LowEndSpirit, the last octet of your local network would usually determine the ports open to you."
	echo "If the last octet of your IP is xxx, then expect ports from xxx01 to xxx20 to be open to you."
	echo ""

	echo "Here are your IPv4 addresses:"
	echo $(ifconfig | awk '/inet addr/{print substr($2,6)}')
	echo ""

	read -p 'Enter port for daemon: ' daemonPort
	echo "You have entered port $daemonPort as the port for the Syncthing relay daemon to listen on."

	echo ""

	read -p 'Enter port for status: ' statusPort
	echo "You have entered port $statusPort as the port for the Syncthing relay status to listen on."
elif [[ "$nat" == [Nn] ]] || [[ -z "$nat" ]]
then
	echo ""
	echo "Assuming that ports 22067 (daemon) and 22068 (status) are readily available for usage."

	daemonPort=22067
	statusPort=22068
else
	echo "User has not entered a valid response, unable to determine the ports to listen on."
	echo "Exiting."
	exit 0;
fi

# start setup process (fully automated and does not need human intervention anymore)

echo ""
echo -n "Updating apt repositories..."
apt-get update -y &>/dev/null
echo "$(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo "Installing packages: dtrx, sed, sudo, supervisor, wget if not installed yet."
apt-get install dtrx sed sudo supervisor wget -y &>/dev/null

# detect architecture
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
echo -n "Adding a user for relaysrv, called relaysrv."
adduser relaysrv --gecos '' --disabled-password &> /dev/null
mkdir /etc/relaysrv
touch /home/relaysrv/syncthingRelay.log
chown -R relaysrv /etc/relaysrv /home/relaysrv
echo "...$(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Copying Syncthing Relay supervisord configuration to the respective folder..."
wget -q "https://raw.githubusercontent.com/theroyalstudent/setupSimpleSyncthingRelay/master/syncthingRelay.conf" -O "/etc/supervisor/conf.d/syncthingRelay.conf" && echo "  $(tput setaf 2)DONE$(tput sgr0)" || (echo "  $(tput setaf 1)FAILED$(tput sgr0)" && echo "" && echo "Exiting." && echo "" && exit 0)

echo ""
echo "Setting name of the Syncthing relay..."
sed -i s/RELAYNAME/"$displayName"/ /etc/supervisor/conf.d/syncthingRelay.conf
echo "...$(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo "Setting ports for the Syncthing relay to listen on..."
sed -i s/daemonPort/"$daemonPort"/ /etc/supervisor/conf.d/syncthingRelay.conf
sed -i s/daemonPort/"$daemonPort"/ /etc/supervisor/conf.d/syncthingRelay.conf
sed -i s/statusPort/"$statusPort"/ /etc/supervisor/conf.d/syncthingRelay.conf
echo "...$(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo "Restarting supervisord..."
sudo service supervisor restart

echo ""
echo "And you should be up and running! (http://relays.syncthing.net)"
echo "If this script worked, feel free to give my script a star!"
echo "Exiting."
echo ""
exit 0
