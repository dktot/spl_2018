#!/bin/bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE="simplicity.conf"
SIMPLICITY_DAEMON="/usr/local/bin/simplicityd"
SIMPLICITY_REPO="https://github.com/ComputerCraftr/Simplicity"
DEFAULTSIMPLICITYPORT=11957
DEFAULTSIMPLICITYUSER="simplicity"
NODEIP=$(curl -s4 icanhazip.com)


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'


function compile_error() {
if [ "$?" -gt "0" ];
 then
  echo -e "${RED}Failed to compile $@. Please investigate.${NC}"
  exit 1
fi
}


function checks() {
if [[ $(lsb_release -d) != *16.04* ]]; then
  echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

if [ -n "$(pidof $SIMPLICITY_DAEMON)" ] || [ -e "$SIMPLICITY_DAEMOM" ] ; then
  echo -e "${GREEN}\c"
  read -e -p "Simplicity is already installed. Do you want to add another MN? [Y/N]" NEW_SIMPLICITY
  echo -e "{NC}"
  clear
else
  NEW_SIMPLICITY="new"
fi
}

function prepare_system() {
echo -e "Prepare the system to install Simplicity v1.2.0.0 master node."
apt-get update >/dev/null 2>&1
apt-get upgrade -y >/dev/null 2>&1
apt-get install -y wget nano unrar unzip >/dev/null 2>&1
apt-get install -y libboost-all-dev libboost-dev >/dev/null 2>&1
apt-get install -y libboost-chrono-dev libboost-filesystem-dev >/dev/null 2>&1
apt-get install -y libboost-program-options-dev >/dev/null 2>&1
apt-get install -y libboost-system-dev libboost-test-dev libboost-thread-dev automake pwgen curl >/dev/null 2>&1
apt-get install -y libgmp3-dev libevent-dev >/dev/null 2>&1
apt-get install -y software-properties-common >/dev/null 2>&1
apt-get install -y protobuf-compiler libminiupnpc-dev >/dev/null 2>&1
apt-get install -y libtool libssl-dev >/dev/null 2>&1
apt-get install -y libprotobuf-dev libqrencode-dev autoconf >/dev/null 2>&1
apt-get install -y build-essential git autotools-dev automake >/dev/null 2>&1
apt-get install -y pkg-config bsdmainutils python3 >/dev/null 2>&1
apt-get install -y python-software-properties >/dev/null 2>&1
apt-get install -y htop >/dev/null 2>&1

#BerkeleyDB
echo -e "${GREEN}Adding bitcoin PPA repository"
apt-add-repository -y ppa:bitcoin/bitcoin >/dev/null 2>&1
apt-get update >/dev/null 2>&1
apt-get install -y libdb4.8-dev libdb4.8++-dev >/dev/null 2>&1

echo -e "Installing required packages, it may take some time to finish.${NC}"
apt-get -y dist-upgrade >/dev/null 2>&1



if [ "$?" -gt "0" ];
  then
    echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
    echo "apt-get update"
    echo "apt -y install software-properties-common"
    echo "apt-add-repository -y ppa:bitcoin/bitcoin"
    echo "apt-get update"
    echo "apt install -y make build-essential libtool software-properties-common autoconf libssl-dev libboost-dev libboost-chrono-dev libboost-filesystem-dev \
libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev sudo automake git pwgen curl libdb4.8-dev \
bsdmainutils libdb4.8++-dev libminiupnpc-dev libgmp3-dev"
 exit 1
fi

clear
echo -e "Checking if swap space is needed."
PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
SWAP=$(free -g|awk '/^Swap:/{print $2}')
if [ "$PHYMEM" -lt "2" ] && [ -n "$SWAP" ]
  then
    echo -e "${GREEN}Server is running with less than 2G of RAM without SWAP, creating 2G swap file.${NC}"
    SWAPFILE=$(mktemp)
    dd if=/dev/zero of=$SWAPFILE bs=1024 count=2M
    chmod 600 $SWAPFILE
    mkswap $SWAPFILE
    swapon -a $SWAPFILE
else
  echo -e "${GREEN}Server running with at least 2G of RAM, no swap needed.${NC}"
fi
clear
}


function enable_firewall() {
  FWSTATUS=$(ufw status 2>/dev/null|awk '/^Status:/{print $NF}')
  if [ "$FWSTATUS" = "active" ]; then
    echo -e "Setting up firewall to allow ingress on port ${GREEN}$ASTRUMPORT${NC}"
    ufw allow $SIMPLICITYPORT/tcp comment "Simplicity MN port" >/dev/null
  fi
  
 # Install fail2ban if needed
    echo && echo "Installing fail2ban..."
    sleep 3
    sudo apt-get -y install fail2ban
    sudo service fail2ban restart    
}



function compile_simplicity() {
  echo -e "Clone git repo and compile it. This may take some time. Press a key to continue."
  git clone $SIMPLICITY_REPO

  cd Simplicity-1.2.0.0/src/secp256k1
  chmod +x autogen.sh
  ./autogen.sh
  ./configure
  make
  sudo make install
  ./tests
  sleep 5
  
  cd
  cd Simplicity-1.2.0.0/src/leveldb
  chmod +x build_detect_platform
  sudo ./build_detect_platform build_config.mk .
  cd ..
  sudo make -f makefile.unix
  cp -a simplicityd /usr/local/bin
  LD_LIBRARY_PATH=/usr/local/lib && export LD_LIBRARY_PATH
  cd ~
  clear
}




function systemd_simplicity() {
  cat << EOF > /etc/systemd/system/$SIMPLICITYUSER.service
[Unit]
Description=Simplicity service
After=network.target

[Service]
ExecStart=$SIMPLICITY_DAEMON -conf=$SIMPLICITYFOLDER/$CONFIG_FILE -datadir=$SIMPLICITYFOLDER
ExecStop=$SIMPLICITY_DAEMON -conf=$SIMPLICITYFOLDER/$CONFIG_FILE -datadir=$SIMPLICITYFOLDER stop
Restart=on-abord
User=$SIMPLICITYUSER
Group=$SIMPLICITYUSER

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $SIMPLICITYUSER.service
  systemctl enable $SIMPLICITYUSER.service

  if [[ -z "$(ps axo user:15,cmd:100 | egrep ^$SIMPLICITYUSER | grep $SIMPLICITY_DAEMON)" ]]; then
    echo -e "${RED}simplicityd is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo "systemctl start $SIMPLICITYUSER.service"
    echo "systemctl status $SIMPLICITYUSER.service"
    echo "less /var/log/syslog"
    exit 1
  fi
}


function ask_port() {
read -p "SIMPLICITY Port: " -i $DEFAULTSIMPLICITYPORT -e SIMPLICITYPORT
: ${SIMPLICITYPORT:=$DEFAULTSIMPLICITYPORT}
}


function ask_user() {
  read -p "Simplicity user: " -i $DEFAULTSIMPLICITYUSER -e SIMPLICITYUSER
  : ${SIMPLICITYUSER:=$DEFAULTSIMPLICITYUSER}

  if [ -z "$(getent passwd $SIMPLICITYUSER)" ]; then
    USERPASS=$(pwgen -s 12 1)
    useradd -m $SIMPLICITYUSER
    echo "$SIMPLICITYUSER:$USERPASS" | chpasswd

    SIMPLICITYHOME=$(sudo -H -u $SIMPLICITYUSER bash -c 'echo $HOME')
    DEFAULTSIMPLICITYFOLDER="$SIMPLICITYHOME/.simplicity"
    read -p "Configuration folder: " -i $DEFAULTSIMPLICITYFOLDER -e SIMPLICITYFOLDER
    : ${SIMPLICITYFOLDER:=$DEFAULTSIMPLICITYFOLDER}
    mkdir -p $SIMPLICITYFOLDER
    chown -R $SIMPLICITYUSER: $SIMPLICITYFOLDER >/dev/null
  else
    clear
    echo -e "${RED}User exits. Please enter another username: ${NC}"
    ask_user
  fi
}


function check_port() {
  declare -a PORTS
  PORTS=($(netstat -tnlp | awk '/LISTEN/ {print $4}' | awk -F":" '{print $NF}' | sort | uniq | tr '\r\n'  ' '))
  ask_port

  while [[ ${PORTS[@]} =~ $SIMPLICITYPORT ]] || [[ ${PORTS[@]} =~ $[SIMPLICITYPORT+1] ]]; do
    clear
    echo -e "${RED}Port in use, please choose another port:${NF}"
    ask_port
  done
}



function create_config() {
  RPCUSER=$(pwgen -s 8 1)
  RPCPASSWORD=$(pwgen -s 15 1)
  cat << EOF > $SIMPLICITYFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcallowip=127.0.0.1
rpcport=$[SIMPLICITYPORT+1]
listen=1
mnconflock=0
server=1
listen=1
staking=0
server=1
daemon=1
port=$SIMPLICITYPORT
EOF
}

function create_key() {
  echo -e "Enter your ${RED}Masternode Private Key${NC}. Leave it blank to generate a new ${RED}Masternode Private Key${NC} for you:"
  read -e SIMPLICITYKEY
  if [[ -z "$SIMPLICITYKEY" ]]; then
  sudo -u $SIMPLICITYUSER $SIMPLICITY_DAEMON -conf=$SIMPLICITYFOLDER/$CONFIG_FILE -datadir=$SIMPLICITYFOLDER
  sleep 5
  if [ -z "$(ps axo user:15,cmd:100 | egrep ^$SIMPLICITYUSER | grep $SIMPLICITY_DAEMON)" ]; then
   echo -e "${RED}simplicityd server couldn't start. Check /var/log/syslog for errors.{$NC}"
   exit 1
  fi
  SIMPLICITYKEY=$(sudo -u $SIMPLICITYUSER $SIMPLICITY_DAEMON -conf=$SIMPLICITYFOLDER/$CONFIG_FILE -datadir=$SIMPLICITYFOLDER masternode genkey)
  sudo -u $SIMPLICITYUSER $SIMPLICITY_DAEMON -conf=$SIMPLICITYFOLDER/$CONFIG_FILE -datadir=$SIMPLICITYFOLDER stop
fi
}

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $SIMPLICITYFOLDER/$CONFIG_FILE
  cat << EOF >> $SIMPLICITYFOLDER/$CONFIG_FILE
logtimestamps=1
maxconnections=64
masternode=1
masternodeaddr=$NODEIP:$SIMPLICITYPORT
masternodeprivkey=$SIMPLICITYKEY
EOF
  chown -R $SIMPLICITYUSER: $SIMPLICITYFOLDER >/dev/null
}

function important_information() {
 echo
 echo -e "================================================================================================================================"
 echo -e "Simplicity Masternode is up and running as user ${GREEN}$SIMPLICITYUSER${NC} and it is listening on port ${GREEN}$SIMPLICITYPORT${NC}."
 echo -e "${GREEN}$SIMPLICITYUSER${NC} password is ${RED}$USERPASS${NC}"
 echo -e "Configuration file is: ${RED}$SIMPLICITYFOLDER/$CONFIG_FILE${NC}"
 echo -e "Start: ${RED}systemctl start $SIMPLICITYUSER.service${NC}"
 echo -e "Stop: ${RED}systemctl stop $SIMPLICITYUSER.service${NC}"
 echo -e "VPS_IP:PORT ${RED}$NODEIP:$SIMPLICITYPORT${NC}"
 echo -e "MASTERNODE PRIVATEKEY is: ${RED}$SIMPLICITYKEY${NC}"
 echo -e "Please check Simplicity is running with the following command: ${GREEN}systemctl status $SIMPLICITYUSER.service${NC}"
 echo -e "================================================================================================================================"
}

function setup_node() {
  ask_user
  check_port
  create_config
  create_key
  update_config
  enable_firewall
  systemd_simplicity
  important_information
}


##### Main #####
clear

checks
if [[ ("$NEW_SIMPLICITY" == "y" || "$NEW_SIMPLICITY" == "Y") ]]; then
  setup_node
  exit 0
elif [[ "$NEW_SIMPLICITY" == "new" ]]; then
  prepare_system
  compile_simplicity
  setup_node
else
  echo -e "${GREEN}simplicityd already running.${NC}"
  exit 0
fi
