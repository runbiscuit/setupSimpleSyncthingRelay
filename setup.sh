#!/bin/bash

echo ""
echo "=================================================================="
echo "Simple Syncthing Relay Setup Script by @theroyalstudent (Edwin A.)"
echo "============ [ GitHub Source: https://git.io/vr2xt ] ============="
echo "=================================================================="
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

echo "Deleting old data and making sure no Syncthing Relay is running..."

killall relaysrv &> /dev/null
rm -rf /tmp/relaysrv*.tar.gz /etc/relaysrv /home/relaysrv /usr/local/bin/relaysrv &> /dev/null
userdel relaysrv &> /dev/null

# input relay name

echo ""
read -rp "Please enter a relay name: " relayName

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
read -rp "Is this correct? [Y/n]: " serverIPverification

if [[ "$serverIPverification" == [Nn] ]]
then
	read -rp "Enter correct/preferred name: " serverIPgeolocation
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
echo "$displayName"

# ask user whether he is behind a NAT

echo ""
read -rp "Are you behind a NAT or a firewall? [N/y]: " nat

if [[ "$nat" == [Yy] ]]
then
	echo ""
	echo "On commercial NAT VPS services like LowEndSpirit, the last octet of your local network would usually determine the ports open to you."
	echo "If the last octet of your IP is xxx, then expect ports from xxx01 to xxx20 to be open to you."
	echo ""

	echo "Here are your IPv4 addresses:"
	ip addr | grep "inet " | cut -d ' ' -f 6 | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'
	echo ""

	read -rp 'Enter port for daemon: ' daemonPort
	echo "You have entered port $daemonPort as the port for the Syncthing relay daemon to listen on."

	echo ""

	read -rp 'Enter port for status: ' statusPort
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

# start setup process
# Check if supervisor is installed first
defaultConfPath="/etc/supervisor/conf.d/syncthingRelay.conf"
supConfPath="$defaultConfPath"
newInstall=false

if ! which supervisord &> /dev/null; then
	echo "Installing supervisor"
	newInstall=true
	# detecting apt-get/yum
	if which apt-get &> /dev/null; then
		echo ""
		echo -n "Updating apt repositories..."
		apt-get update -y &>/dev/null
		echo "  $(tput setaf 2)DONE$(tput sgr0)"
		echo ""
		echo -n "Installing packages: sed, sudo, supervisor if not installed yet..."
		apt-get install sed sudo supervisor -y &>/dev/null
		echo "  $(tput setaf 2)DONE$(tput sgr0)"
	elif which yum &> /dev/null; then
		echo ""
		echo -n "Updating yum repositories..."
		yum check-update &>/dev/null
		echo "  $(tput setaf 2)DONE$(tput sgr0)"
		echo ""
		if yum search supervisor &> /dev/null; then
			echo "Installing supervisor with yum"
			yum -qy install sed sudo supervisor
		else
			echo -n "Supervisor not found in yum repo, installing via Python easy_install"
			yum -qy install sed sudo python-setuptools &> /dev/null
			easy_install supervisor &>/dev/null
			mkdir -p /var/run/supervisord
			chmod 755 /var/run/supervisord
			wget -q "https://raw.githubusercontent.com/theroyalstudent/setupSimpleSyncthingRelay/master/supervisord-yum.sh" -O "/etc/rc.d/init.d/supervisord" &>/dev/null
			chmod 755 /etc/rc.d/init.d/supervisord
		fi
		mkdir -p /etc/supervisor/conf.d
		# echo_supervisord_conf is provided by supervisor
		echo_supervisord_conf > /etc/supervisord.conf
		# Modify it to include from conf.d by default
		sed -i "s/\;\[include\]/[include]/" /etc/supervisord.conf
		sed -i "s/\;files.*/files = \/etc\/supervisor\/conf.d\/*.conf/" /etc/supervisord.conf
		echo "  $(tput setaf 2)DONE$(tput sgr0)"
	else
		echo "unsupported or unknown architecture"
		echo ""
		exit;
	fi
else
	echo "Supervisor is already installed. Where should the supervisor config for relaysrv be installed?"
	read -rp "Default - $defaultConfPath: " supConfPath
	if [[ -z "$supConfPath" ]]; then
		supConfPath="$defaultConfPath"
		echo "Using default path - $supConfPath"
	fi
fi

# detect architecture
if uname -m | grep -q 64; then
	cpubits="linux-amd64"
	cpubitsname="for (64bit)..."
elif uname -m | grep -q 86; then
	cpubits="linux-386"
	cpubitsname="for (32bit)..."
elif uname -m | grep -q "armv"; then
	cpubits="linux-arm"
	cpubitsname="for (ARM)..."
else
	echo "unsupported or unknown architecture"
	echo ""
	exit;
fi

echo ""
echo "Downloading latest release of the relaysrv daemon $cpubitsname"
cd /tmp || exit
wget "$(wget https://api.github.com/repos/syncthing/relaysrv/releases/latest -qO - | grep 'browser_' | grep $cpubits | cut -d\" -f4)" &>/dev/null

echo ""
echo -n "Extracting the relaysrv daemon..."
tar --strip=1 -xaf relaysrv-linux*.tar.gz '*relaysrv'
echo "  $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Moving the relaysrv daemon to /usr/local/bin..."
mv relaysrv /usr/local/bin
echo "  $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Clearing up the remains of the relaysrv daemon."
rm -rf relaysrv-linux*.tar.gz
echo "  $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Adding a user for relaysrv, called relaysrv."
mkdir /etc/relaysrv
useradd -r -d /etc/relaysrv -s /sbin/nologin relaysrv &> /dev/null
chown -R relaysrv /etc/relaysrv
touch /etc/relaysrv/syncthingRelay.log

echo ""
echo -n "Copying Syncthing Relay supervisord configuration to the respective folder..."
if wget -q "https://raw.githubusercontent.com/theroyalstudent/setupSimpleSyncthingRelay/master/syncthingRelay.conf" -O "$supConfPath"; then
	echo "  $(tput setaf 2)DONE$(tput sgr0)"
else
	echo "  $(tput setaf 1)FAILED$(tput sgr0)"
	echo ""
	echo "Exiting."
	echo ""
	exit;
fi

echo ""
echo -n "Setting name of the Syncthing relay..."
sed -i s/RELAYNAME/"$displayName"/ $supConfPath
echo "  $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo -n "Setting ports for the Syncthing relay to listen on..."
sed -i s/daemonPort/"$daemonPort"/g $supConfPath
sed -i s/statusPort/"$statusPort"/ $supConfPath
echo " $(tput setaf 2)DONE$(tput sgr0)"

echo ""
echo "Restarting supervisord..."
echo ""
# Restarting supervisord also kills any running processes, which is bad
# Use supervisorctl update if supervisor was already installed
if "$newInstall" = "true"; then
	# Check for both sysvinit & systemd
	if [[ -e "/etc/rc.d/init.d/supervisord" || -e "/usr/lib/systemd/system/supervisord.service" ]]; then
		service supervisord restart
	else
		service supervisor restart
	fi
else
	supervisorctl update
fi

echo "Sleeping for 12 seconds to let supervisord stabilize"
sleep 12
supervisorctl status syncthingRelay
echo "And you should be up and running! (http://relays.syncthing.net)"
echo "If this script worked, feel free to give my script a star!"
echo "Exiting."
echo ""
exit 0
