#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"

NAMADA_TAG=v0.15.3
TM_HASH=v0.1.4-abciplus
CHAIN_ID="public-testnet-8.0.b92ef72b820"

if [ ! $ALIAS ]; then
	read -p "Enter node name: " VALIDATOR_ALIAS
	echo 'export VALIDATOR_ALIAS='\"${VALIDATOR_ALIAS}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
. $HOME/.bash_profile

# update
cd $HOME
sudo apt update
sudo apt install make clang pkg-config git-core libssl-dev build-essential libclang-12-dev git jq ncdu bsdmainutils htop -y

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

sudo apt-get update -y
sudo apt-get install build-essential make pkg-config libssl-dev libclang-dev -y
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# install go
if ! [ -x "$(command -v go)" ]; then
  ver="1.19.4"
  cd $HOME
wget -O go1.19.4.linux-amd64.tar.gz https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz && sudo rm go1.19.4.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
fi

# download binary
cd $HOME && sudo rm -rf $HOME/namada 
wget -O namada-v0.15.3-Linux-x86_64.tar.gz https://github.com/anoma/namada/releases/download/v0.15.3/namada-v0.15.3-Linux-x86_64.tar.gz
tar xvf namada-v0.15.3-Linux-x86_64.tar.gz
sudo mv namada-v0.15.3-Linux-x86_64/namada /usr/local/bin/
sudo mv namada-v0.15.3-Linux-x86_64/namada[c,n,w] /usr/local/bin/

cd $HOME && sudo rm -rf tendermint 
git clone https://github.com/heliaxdev/tendermint 
cd tendermint 
git checkout $TM_HASH
make build
sudo mv build/tendermint /usr/local/bin/
cd $HOME
namada client utils join-network --chain-id $CHAIN_ID

# create service
echo "[Unit]
Description=Namada Node
After=network.target
[Service]
User=$USER
WorkingDirectory=$HOME/.namada
Type=simple
ExecStart=/usr/local/bin/namada --base-dir=$HOME/.namada node ledger run 
RemainAfterExit=no
Restart=always
RestartSec=5s
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > $HOME/namadad.service
sudo mv $HOME/namadad.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

# start service
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable namadad
sudo systemctl restart namadad

break
;;

"Create Validator")
namada wallet address gen --alias $VALIDATOR_ALIAS
namada client init-validator \
  --alias $VALIDATOR_ALIAS \
  --source $VALIDATOR_ALIAS \
  --commission-rate 0.05 \
  --max-commission-rate-change 0.01
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
