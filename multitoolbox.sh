#!/bin/bash

if ! [[ -z $1 ]]; then
    if [[ $BRANCH_ALREADY_REFERENCED != '1' ]]; then
        export ROOT_BRANCH="$1"
        export BRANCH_ALREADY_REFERENCED='1'
        bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/multitoolbox.sh) $ROOT_BRANCH
        unset ROOT_BRANCH
        unset BRANCH_ALREADY_REFERENCED
        exit
    fi
else
    export ROOT_BRANCH='master'
fi

source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/flux_common.sh)"


if [[ -d /home/$USER/.zelcash ]]; then
   CONFIG_DIR='.zelcash'
   CONFIG_FILE='zelcash.conf'
    
else
    CONFIG_DIR='.flux'
    CONFIG_FILE='flux.conf'
fi

FLUX_DIR='zelflux'
FLUX_APPS_DIR='ZelApps'
COIN_NAME='zelcash'
Server_offline=0

dversion="v7.3"
PM2_INSTALL="0"
zelflux_setting_import="0"


function config_veryfity(){

 if [[ -f /home/$USER/.flux/flux.conf ]]; then
 
    echo -e "${ARROW} ${YELLOW}Checking config file...${NC}"
    insightexplorer=$(cat /home/$USER/.flux/flux.conf | grep 'insightexplorer=1' | wc -l)

    if [[ "$insightexplorer" == "1" ]]; then
  
      echo -e "${ARROW} ${CYAN}Insightexplorer enabled.............[${CHECK_MARK}${CYAN}]${NC}"
      echo ""

    else
    
      echo -e "${WORNING} ${CYAN}Insightexplorer enabled.............[${X_MARK}${CYAN}]${NC}"
      echo -e "${WORNING} ${CYAN}Use option 2 for node re-install${NC}"
      echo -e ""
      exit

    fi
  
  fi

}


function config_file() {

if [[ -f /home/$USER/install_conf.json ]]; then

import_settings=$(cat /home/$USER/install_conf.json | jq -r '.import_settings')
bootstrap_url=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_url')
bootstrap_zip_del=$(cat /home/$USER/install_conf.json | jq -r '.bootstrap_zip_del')
use_old_chain=$(cat /home/$USER/install_conf.json | jq -r '.use_old_chain')
prvkey=$(cat /home/$USER/install_conf.json | jq -r '.prvkey')
outpoint=$(cat /home/$USER/install_conf.json | jq -r '.outpoint')
index=$(cat /home/$USER/install_conf.json | jq -r '.index')
zel_id=$(cat /home/$USER/install_conf.json | jq -r '.zelid')
kda_address=$(cat /home/$USER/install_conf.json | jq -r '.kda_address')

echo -e "${ARROW} ${YELLOW}Install config summary:"
if [[ "$prvkey" != "" && "$outpoint" != "" && "$index" != "" ]];then
echo -e "${PIN}${CYAN}Import settings from install_conf.json...........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else

if [[ "$import_settings" == "1" ]]; then
echo -e "${PIN}${CYAN}Import settings from exist config files..........................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

fi

if [[ "$use_old_chain" == "1" ]]; then
echo -e "${PIN}${CYAN}Diuring re-installation old chain will be use....................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1

else

if [[ "$bootstrap_url" == "" ]]; then
echo -e "${PIN}${CYAN}Use Flux Bootstrap from source build in scripts..................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else
echo -e "${PIN}${CYAN}Use Flux Bootstrap from own source...............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ "$bootstrap_zip_del" == "1" ]]; then
echo -e "${PIN}${CYAN}Remove Flux Bootstrap archive file...............................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else
echo -e "${PIN}${CYAN}Leave Flux Bootstrap archive file................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

fi


if [[ ( "$discord" != "" && "$discord" != "0" ) || "$telegram_alert" == '1' ]]; then
echo -e "${PIN}${CYAN}Enable watchdog notification.....................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
else
echo -e "${PIN}${CYAN}Disable watchdog notification....................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

if [[ ( "$enable_upnp" != "" && "$enable_upnp" != "0" ) ]]; then
  echo -e "${PIN}${CYAN}Enable UPnP configuration........................................[${CHECK_MARK}${CYAN}]${NC}" && sleep 0.5
  echo -e "${CYAN}   UPnP Port:  ${GREEN}$upnp_port${NC}" && sleep 0.5
  echo -e "${CYAN}   Gateway IP: ${GREEN}$gateway_ip${NC}" && sleep 0.5
fi

fi
}



function install_flux() {

echo -e "${GREEN}Module: Re-install FluxOS${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" || "$USER" == "ubuntu" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

 if pm2 -v > /dev/null 2>&1; then
 pm2 del zelflux > /dev/null 2>&1
 pm2 del flux > /dev/null 2>&1
 pm2 save > /dev/null 2>&1
 fi
 
docker_check=$(docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" | wc -l)
resource_check=$(df | egrep 'flux' | awk '{ print $1}' | wc -l)
mongod_check=$(mongoexport -d localzelapps -c zelappsinformation --jsonArray --pretty --quiet  | jq -r .[].name | head -n1)

if [[ "$mongod_check" != "" && "$mongod_check" != "null" ]]; then
echo -e "${ARROW} ${YELLOW}Detected Flux MongoDB local apps collection ...${NC}" && sleep 1
echo -e "${ARROW} ${CYAN}Cleaning MongoDB Flux local apps collection...${NC}" && sleep 1
echo "db.zelappsinformation.drop()" | mongo localzelapps > /dev/null 2>&1
fi

if [[ $docker_check != 0 ]]; then
echo -e "${ARROW} ${YELLOW}Detected running docker container...${NC}" && sleep 1
echo -e "${ARROW} ${CYAN}Removing containers...${NC}"
sudo aa-remove-unknown > /dev/null 2>&1 && sudo service docker restart > /dev/null 2>&1 && sleep 2 

#docker ps | grep -Eo "^[0-9a-z]{8,}\b" |
docker container ls -a | egrep 'zelcash|flux' | grep -Eo "^[0-9a-z]{8,}\b" |
while read line; do
sudo docker stop $line > /dev/null 2>&1 && sleep 2 
sudo docker rm $line > /dev/null 2>&1 && sleep 2 
done
fi

if [[ $resource_check != 0 ]]; then
echo -e "${ARROW} ${YELLOW}Detected locked resource...${NC}" && sleep 1
echo -e "${ARROW} ${CYAN}Unmounting locked Flux resource${NC}" && sleep 1
df | egrep 'flux' | awk '{ print $1}' |
while read line; do
sudo umount -l $line && sleep 1
done
fi

if [ -f /home/$USER/$FLUX_DIR/config/userconfig.js ]; then

    echo -e "${ARROW} ${CYAN}Importing setting...${NC}"
    zel_id=$(grep -w zelid /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*zelid: .//' | sed -e 's/.\{2\}$//')
    WANIP=$(grep -w ipaddress /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*ipaddress: .//' | sed -e 's/.\{2\}$//')
    
    echo -e "${PIN}${CYAN}Zel ID = ${GREEN}$zel_id${NC}" && sleep 1
    
    KDA_A=$(grep -w kadena /home/$USER/$FLUX_DIR/config/userconfig.js | sed -e 's/.*kadena: .//' | sed -e 's/.\{2\}$//')
    
    if [[ "$KDA_A" != "" ]]; then
    
    echo -e "${PIN}${CYAN}Kadena address = ${GREEN}$KDA_A${NC}" && sleep 1
    
    fi
    
   
    echo -e "${PIN}${CYAN}IP = ${GREEN}$WANIP${NC}" && sleep 1   
    echo 
    echo -e "${ARROW} ${CYAN}Removing any instances of Flux....${NC}"
    sudo rm -rf $FLUX_DIR  > /dev/null 2>&1 && sleep 2
    #sudo rm -rf zelflux  > /dev/null 2>&1 && sleep 2
    zelflux_setting_import="1"

fi

if [ -d /home/$USER/$FLUX_DIR ]; then

    echo -e "${ARROW} ${CYAN}Removing any instances of Flux....${NC}"
    #sudo rm -rf zelflux  > /dev/null 2>&1 && sleep 2
    sudo rm -rf $FLUX_DIR  > /dev/null 2>&1 && sleep 2
    
fi

echo -e "${ARROW} ${CYAN}Flux downloading...${NC}"
#git clone --single-branch --branch development https://github.com/RunOnFlux/flux.git zelflux > /dev/null 2>&1 && sleep 2
git clone https://github.com/RunOnFlux/flux.git zelflux > /dev/null 2>&1 && sleep 2

if [ -d /home/$USER/$FLUX_DIR ]
then

if [[ -f /home/$USER/$FLUX_DIR/package.json ]]; then
  current_ver=$(jq -r '.version' /home/$USER/$FLUX_DIR/package.json)
else
  string_limit_x_mark "Flux was not downloaded, run script again..........................................."
  echo
  exit
fi

string_limit_check_mark "Flux v$current_ver downloaded..........................................." "Flux ${GREEN}v$current_ver${CYAN} downloaded..........................................."
else
string_limit_x_mark "Flux was not downloaded, run script again..........................................."
echo
exit
fi


if [[ "$zelflux_setting_import" == "0" ]]; then

ip_confirm

while true
  do
    zel_id="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"
    if [ $(printf "%s" "$zel_id" | wc -c) -eq "34" ] || [ $(printf "%s" "$zel_id" | wc -c) -eq "33" ]; then
      string_limit_check_mark "Zel ID is valid..........................................."
      break
    else
      string_limit_x_mark "Zel ID is not valid try again..........................................."
      sleep 2
   fi

 done
 
 
  touch ~/$FLUX_DIR/config/userconfig.js
    cat << EOF > ~/$FLUX_DIR/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '${WANIP}',
        zelid: '${zel_id}',
        testnet: false
      }
    }
EOF

else

if [[ "$KDA_A" != "" ]]; then

  touch ~/$FLUX_DIR/config/userconfig.js
    cat << EOF > ~/$FLUX_DIR/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '${WANIP}',
        zelid: '${zel_id}',
	kadena: '${KDA_A}',
        testnet: false
      }
    }
EOF

else

  touch ~/$FLUX_DIR/config/userconfig.js
    cat << EOF > ~/$FLUX_DIR/config/userconfig.js
module.exports = {
      initial: {
        ipaddress: '${WANIP}',
        zelid: '${zel_id}',
        testnet: false
      }
    }
EOF

fi

fi
   
if [[ -f /home/$USER/$FLUX_DIR/config/userconfig.js ]]; then
string_limit_check_mark "Flux configuration successfull..........................................."
else
string_limit_x_mark "Flux installation failed, missing config file..........................................."
echo
exit
fi

 if pm2 -v > /dev/null 2>&1; then 
 
   rm restart_zelflux.sh > /dev/null 2>&1
   pm2 del flux > /dev/null 2>&1
   pm2 del zelflux > /dev/null 2>&1
   pm2 save > /dev/null 2>&1
   echo -e "${ARROW} ${CYAN}Starting Flux....${NC}"
   echo -e "${ARROW} ${CYAN}Flux loading will take 2-3min....${NC}"
   echo
   pm2 start /home/$USER/$FLUX_DIR/start.sh --restart-delay=60000 --max-restarts=40 --name flux --time  > /dev/null 2>&1
   pm2 save > /dev/null 2>&1
   pm2 list

 else
 
    pm2_install()
    if [[ "$PM2_INSTALL" == "1" ]]; then
      echo -e "${ARROW} ${CYAN}Starting Flux....${NC}"
      echo -e "${ARROW} ${CYAN}Flux loading will take 2-3min....${NC}"
      echo
      pm2 list
    fi
 fi

}

function create_config() {


if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${GREEN}Module: Create FluxNode installation config file${NC}"
echo -e "${YELLOW}================================================================${NC}"


if jq --version > /dev/null 2>&1; then
  sleep 0.2
else
  echo -e "${ARROW} ${YELLOW}Installing JQ....${NC}"
  sudo apt  install jq -y > /dev/null 2>&1

    if jq --version > /dev/null 2>&1
    then
      #echo -e "${ARROW} ${CYAN}Nodejs version: ${GREEN}$(node -v)${CYAN} installed${NC}"
      string_limit_check_mark "JQ $(jq --version) installed................................." "JQ ${GREEN}$(jq --version)${CYAN} installed................................."
      echo
    else
     #echo -e "${ARROW} ${CYAN}Nodejs was not installed${NC}"
      string_limit_x_mark "JQ was not installed................................."
      echo
      exit
    fi
fi

skip_zelcash_config='0'
skip_bootstrap='0'

if [[ -d /home/$USER/$CONFIG_DIR ]]; then

  if whiptail --yesno "Would you like import old settings from daemon and Flux?" 8 65; then
     import_settings='1'
     skip_zelcash_config='1'
     sleep 1
  else
     import_settings='0'
     sleep 1
  fi

  if whiptail --yesno "Would you like use exist Flux chain?" 8 65; then
    use_old_chain='1'
    skip_bootstrap='1'
    sleep 1
  else
    use_old_chain='0'
    sleep 1
  fi
  
fi

if [[ "$skip_zelcash_config" == "1" ]]; then

  prvkey=""
  outpoint=""
  index=""
  zelid=""
  kda_address=""
  node_label="0" 
  fix_action="1"      
  eps_limit="0"
  discord="0"
  ping="0"
  telegram_alert="0"    
  telegram_bot_token="0"	      	      
  telegram_chat_id="0"	
   
else

  prvkey=$(whiptail --inputbox "Enter your FluxNode Identity Key from Zelcore" 8 65 3>&1 1>&2 2>&3)
  sleep 1
  outpoint=$(whiptail --inputbox "Enter your FluxNode Collateral TX ID from Zelcore" 8 72 3>&1 1>&2 2>&3)
  sleep 1
  index=$(whiptail --inputbox "Enter your FluxNode Output Index from Zelcore" 8 65 3>&1 1>&2 2>&3)
  sleep 1
  zel_id=$(whiptail --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)
  sleep 1
  KDA_A=$(whiptail --inputbox "Please enter your Kadena address from Zelcore" 8 85 3>&1 1>&2 2>&3)
  sleep 1

    if whiptail --yesno "Would you like enable autoupdate?" 8 65; then
      zelflux_update='1'
      zelcash_update='1'
      zelbench_update='1'
    else
      zelflux_update='0'
      zelcash_update='0'
      zelbench_update='0'   
    fi


  if [[ "$KDA_A" == "" ]]; then 
      kda_address=""
  else
      kda_address="kadena:$KDA_A?chainid=0"
  fi

  if whiptail --yesno "Would you like to enable UPnP for this node?" 8 65; then
    enable_upnp='1'
    gateway_ip=$(whiptail --inputbox "Enter your UPnP Gateway IP: (This is usually your router)" 8 85 3>&1 1>&2 2>&3)
    upnp_port=$(whiptail --title "Enter your FluxOS UPnP Port" --radiolist \
      "Use the UP/DOWN arrows to highlight the port you want. Press Spacebar on the port you want to select, THEN press ENTER." 17 50 8 \
      "16127" "" ON \
      "16137" "" OFF \
      "16147" "" OFF \
      "16157" "" OFF \
      "16167" "" OFF \
      "16177" "" OFF \
      "16187" "" OFF \
      "16197" "" OFF 3>&1 1>&2 2>&3)
  else
    enable_upnp="0"
    gateway_ip=""
    upnp_port=""
  fi
    
  if whiptail --yesno "Would you like enable alert notification?" 8 65; then

      whiptail --msgbox "Info: to select/deselect item use 'space' ...to switch to OK/Cancel use 'tab' " 10 60
      sleep 1

      CHOICES=$(whiptail --title "Choose options: " --separate-output --checklist "Choose options: " 10 45 5 \
      "1" "Discord notification      " ON \
      "2" "Telegram notification     " OFF 3>&1 1>&2 2>&3 )

      if [ -z "$CHOICES" ]; then

        echo -e "${ARROW} ${CYAN}No option was selected...Alert notification disabled! ${NC}"
        sleep 1
        discord="0"
        ping="0"
        telegram_alert="0"
        telegram_bot_token="0"
        telegram_chat_id="0"
        node_label="0"

      else
      
         for CHOICE in $CHOICES; do
         case "$CHOICE" in
         "1")

            discord=$(whiptail --inputbox "Enter your discord server webhook url" 8 65 3>&1 1>&2 2>&3)
            sleep 1

            if whiptail --yesno "Would you like enable nick ping on discord?" 8 60; then

             while true
             do
               ping=$(whiptail --inputbox "Enter your discord user id" 8 60 3>&1 1>&2 2>&3)
              if [[ $ping == ?(-)+([0-9]) ]]; then
               string_limit_check_mark "UserID is valid..........................................."
               break
              else
               string_limit_x_mark "UserID is not valid try again............................."
               sleep 1
              fi
             done

             sleep 1

            else
             ping="0"
             sleep 1
           fi

         ;;
         "2")

          telegram_alert="1"

         while true
         do
          telegram_bot_token=$(whiptail --inputbox "Enter telegram bot token from BotFather" 8 65 3>&1 1>&2 2>&3)
          if [[ $(grep ':' <<< "$telegram_bot_token") != "" ]]; then
            string_limit_check_mark "Bot token is valid..........................................."
            break
          else
            string_limit_x_mark "Bot token is not valid try again............................."
            sleep 1
         fi
        done

     sleep 1

        while true
        do
        telegram_chat_id=$(whiptail --inputbox "Enter your chat id from GetIDs Bot" 8 60 3>&1 1>&2 2>&3)
        if [[ $telegram_chat_id == ?(-)+([0-9]) ]]; then
           string_limit_check_mark "Chat ID is valid..........................................."
           break
         else
           string_limit_x_mark "Chat ID is not valid try again............................."
           sleep 1
        fi
        done

       sleep 1

      ;;
    esac
  done
fi

 while true
     do
       node_label=$(whiptail --inputbox "Enter name of your node (alias)" 8 65 3>&1 1>&2 2>&3)
        if [[ "$node_label" != "" && "$node_label" != "0"  ]]; then
           string_limit_check_mark "Node name is valid..........................................."
           break
         else
           string_limit_x_mark "Node name is not valid try again............................."
           sleep 1
        fi
    done

else

    discord="0"
    ping="0"
    telegram_alert="0"
    telegram_bot_token="0"
    telegram_chat_id="0"
    node_label="0"
    sleep 1
    
fi


if [[ "$discord" == 0 ]]; then
    ping="0"
fi


if [[ "$telegram_alert" == 0 || "$telegram_alert" == "" ]]; then
    telegram_alert="0"
    telegram_bot_token="0"
    telegram_chat_id="0"
fi

  index_from_file="$index"
  tx_from_file="$outpoint"
  stak_info=$(curl -sSL -m 5 https://explorer.zelcash.online/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
	
if [[ "$stak_info" == "" ]]; then
    stak_info=$(curl -sSL -m 5 https://explorer.zelcash.online/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
fi	

if [[ $stak_info == ?(-)+([0-9]) ]]; then

  case $stak_info in
   "1000") eps_limit=90 ;;
   "12500")  eps_limit=180 ;;
   "40000") eps_limit=300 ;;
  esac
 
else
  eps_limit=0;
fi



if [[ "$skip_bootstrap" == "0" ]]; then

  if whiptail --yesno "Would you like use Flux bootstrap from script source?" 8 65; then
      
    bootstrap_url="0"
    sleep 1

  else
    bootstrap_url=$(whiptail --inputbox "Enter your Flux bootstrap URL" 8 65 3>&1 1>&2 2>&3)
    sleep 1
  fi

  if whiptail --yesno "Would you like keep bootstrap archive file localy?" 8 65; then
    bootstrap_zip_del='0'
    sleep 1
  else
    bootstrap_zip_del='1'
    sleep 1
  fi
  
fi

fi

firewall_disable='1'
swapon='1'

rm /home/$USER/install_conf.json > /dev/null 2>&1
sudo touch /home/$USER/install_conf.json
sudo chown $USER:$USER /home/$USER/install_conf.json
    cat << EOF > /home/$USER/install_conf.json
{
  "import_settings": "${import_settings}",
  "prvkey": "${prvkey}",
  "outpoint": "${outpoint}",
  "index": "${index}",
  "zelid": "${zel_id}",
  "kda_address": "${kda_address}",
  "firewall_disable": "${firewall_disable}",
  "bootstrap_url": "${bootstrap_url}",
  "bootstrap_zip_del": "${bootstrap_zip_del}",
  "swapon": "${swapon}",
  "use_old_chain": "${use_old_chain}",
  "node_label": "${node_label}",
  "zelflux_update": "${zelflux_update}",
  "zelcash_update": "${zelcash_update}",
  "zelbench_update": "${zelbench_update}",
  "discord": "${discord}",
  "ping": "${ping}",
  "telegram_alert": "${telegram_alert}",
  "telegram_bot_token": "${telegram_bot_token}",
  "telegram_chat_id": "${telegram_chat_id}",
  "eps_limit": "${eps_limit}",
  "enable_upnp": "${enable_upnp}",
  "upnp_port": "${FLUX_PORT}",
  "gateway_ip": "${gateway_ip}"
}
EOF

config_file
echo

}


function install_watchdog() {

if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

echo -e "${GREEN}Module: Install watchdog for FluxNode${NC}"
echo -e "${YELLOW}================================================================${NC}"

if ! pm2 -v > /dev/null 2>&1
then
pm2_install
 if [[ "$PM2_INSTALL" == "0" ]]; then
   exit
 fi
echo -e ""
fi

echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
pm2 del watchdog  > /dev/null 2>&1
pm2 save  > /dev/null 2>&1
sudo rm -rf /home/$USER/watchdog  > /dev/null 2>&1

echo -e "${ARROW} ${CYAN}Downloading...${NC}"
cd && git clone https://github.com/RunOnFlux/fluxnode-watchdog.git watchdog > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Installing git hooks....${NC}"
wget https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/$ROOT_BRANCH/post-merge > /dev/null 2>&1
mv post-merge /home/$USER/watchdog/.git/hooks/post-merge
sudo chmod +x /home/$USER/watchdog/.git/hooks/post-merge
echo -e "${ARROW} ${CYAN}Installing watchdog module....${NC}"
cd watchdog && npm install > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Creating config file....${NC}"


if whiptail --yesno "Would you like enable FluxOS auto update?" 8 60; then
flux_update='1'
sleep 1
else
flux_update='0'
sleep 1
fi

if whiptail --yesno "Would you like enable Flux daemon auto update?" 8 60; then
daemon_update='1'
sleep 1
else
daemon_update='0'
sleep 1
fi

if whiptail --yesno "Would you like enable Flux benchmark auto update?" 8 60; then
bench_update='1'
sleep 1
else
bench_update='0'
sleep 1
fi

#if whiptail --yesno "Would you like enable fix action (restart daemon, benchmark, mongodb)?" 8 75; then
fix_action='1'
#sleep 1
#else
#fix_action='0'
##sleep 1
#fi

telegram_alert=0;
discord=0;

if whiptail --yesno "Would you like enable alert notification?" 8 60; then

sleep 1

whiptail --msgbox "Info: to select/deselect item use 'space' ...to switch to OK/Cancel use 'tab' " 10 60

sleep 1

CHOICES=$(whiptail --title "Choose options: " --separate-output --checklist "Choose options: " 10 45 5 \
  "1" "Discord notification      " ON \
  "2" "Telegram notification     " OFF 3>&1 1>&2 2>&3 )

if [ -z "$CHOICES" ]; then

  echo -e "${ARROW} ${CYAN}No option was selected...Alert notification disabled! ${NC}"
  sleep 1
  discord=0;
  ping=0;
  telegram_alert=0;
  telegram_bot_token=0;
  telegram_chat_id=0;
  node_label=0;

else
  for CHOICE in $CHOICES; do
    case "$CHOICE" in
    "1")

      discord=$(whiptail --inputbox "Enter your discord server webhook url" 8 65 3>&1 1>&2 2>&3)
      sleep 1

      if whiptail --yesno "Would you like enable nick ping on discord?" 8 60; then

       while true
       do
           ping=$(whiptail --inputbox "Enter your discord user id" 8 60 3>&1 1>&2 2>&3)
          if [[ $ping == ?(-)+([0-9]) ]]; then
             string_limit_check_mark "UserID is valid..........................................."
             break
           else
             string_limit_x_mark "UserID is not valid try again............................."
             sleep 1
          fi
        done

        sleep 1

      else
        ping=0;
        sleep 1
     fi

      ;;
    "2")

 telegram_alert=1;

  while true
     do
        telegram_bot_token=$(whiptail --inputbox "Enter telegram bot token from BotFather" 8 65 3>&1 1>&2 2>&3)
        if [[ $(grep ':' <<< "$telegram_bot_token") != "" ]]; then
           string_limit_check_mark "Bot token is valid..........................................."
           break
         else
           string_limit_x_mark "Bot token is not valid try again............................."
           sleep 1
        fi
    done

  sleep 1

    while true
     do
        telegram_chat_id=$(whiptail --inputbox "Enter your chat id from GetIDs Bot" 8 60 3>&1 1>&2 2>&3)
        if [[ $telegram_chat_id == ?(-)+([0-9]) ]]; then
           string_limit_check_mark "Chat ID is valid..........................................."
           break
         else
           string_limit_x_mark "Chat ID is not valid try again............................."
           sleep 1
        fi
    done

  sleep 1

      ;;
    esac
  done
fi

 while true
     do
       node_label=$(whiptail --inputbox "Enter name of your node (alias)" 8 65 3>&1 1>&2 2>&3)
        if [[ "$node_label" != "" && "$node_label" != "0"  ]]; then
           string_limit_check_mark "Node name is valid..........................................."
           break
         else
           string_limit_x_mark "Node name is not valid try again............................."
           sleep 1
        fi
    done

  sleep 1


else

    node_label=0;
    discord=0;
    ping=0;
    telegram_alert=0;
    telegram_bot_token=0;
    telegram_chat_id=0;
    sleep 1
fi


if [[ $discord == 0 ]]; then
    ping=0;
fi


if [[ $telegram_alert == 0 ]]; then
    telegram_bot_token=0;
    telegram_chat_id=0;
fi


if [[ -f /home/$USER/$CONFIG_DIR/$CONFIG_FILE ]]; then
  index_from_file=$(grep -w zelnodeindex /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeindex=//')
  tx_from_file=$(grep -w zelnodeoutpoint /home/$USER/$CONFIG_DIR/$CONFIG_FILE | sed -e 's/zelnodeoutpoint=//')
  stak_info=$(curl -s -m 5 https://explorer.zelcash.online/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
	
    if [[ "$stak_info" == "" ]]; then
      stak_info=$(curl -s -m 5 https://explorer.zelcash.online/api/tx/$tx_from_file | jq -r ".vout[$index_from_file] | .value,.n,.scriptPubKey.addresses[0],.spentTxId" | paste - - - - | awk '{printf "%0.f %d %s %s\n",$1,$2,$3,$4}' | grep 'null' | egrep -o '1000|12500|40000')
    fi	
fi

if [[ $stak_info == ?(-)+([0-9]) ]]; then

  case $stak_info in
   "1000") eps_limit=90 ;;
   "12500")  eps_limit=180 ;;
   "40000") eps_limit=300 ;;
  esac
 
else
eps_limit=0;
fi



sudo touch /home/$USER/watchdog/config.js
sudo chown $USER:$USER /home/$USER/watchdog/config.js
    cat << EOF >  /home/$USER/watchdog/config.js
module.exports = {
    label: '${node_label}',
    tier_eps_min: '${eps_limit}',
    zelflux_update: '${flux_update}',
    zelcash_update: '${daemon_update}',
    zelbench_update: '${bench_update}',
    action: '${fix_action}',
    ping: '${ping}',
    web_hook_url: '${discord}',
    telegram_alert: '${telegram_alert}',
    telegram_bot_token: '${telegram_bot_token}',
    telegram_chat_id: '${telegram_chat_id}'
}
EOF

echo -e "${ARROW} ${CYAN}Starting watchdog...${NC}"
pm2 start /home/$USER/watchdog/watchdog.js --name watchdog --watch /home/$USER/watchdog --ignore-watch '"./**/*.git" "./**/*node_modules" "./**/*watchdog_error.log" "./**/*config.js"' --watch-delay 20 > /dev/null 2>&1 
pm2 save > /dev/null 2>&1
if [[ -f /home/$USER/watchdog/watchdog.js ]]
then
current_ver=$(jq -r '.version' /home/$USER/watchdog/package.json)
#echo -e "${ARROW} ${CYAN}Watchdog ${GREEN}v$current_ver${CYAN} installed successful.${NC}"
string_limit_check_mark "Watchdog v$current_ver installed..........................................." "Watchdog ${GREEN}v$current_ver${CYAN} installed..........................................."
else
#echo -e "${ARROW} ${CYAN}Watchdog installion failed.${NC}"
string_limit_x_mark "Watchdog was not installed..........................................."
fi
echo
}



function flux_daemon_bootstrap() {

    echo -e "${GREEN}Module: Restore Flux blockchain from bootstrap${NC}"
    echo -e "${YELLOW}================================================================${NC}"

    if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then    
        echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
        echo -e "${CYAN}Please switch to the user account.${NC}"
        echo -e "${YELLOW}================================================================${NC}"
        echo -e "${NC}"
        exit
    fi

    cd
    echo -e "${NC}"
    
    config_veryfity
    get_ip
    bootstrap_geolocation
    bootstrap_server $continent
    
    
    if [[ "$Server_offline" == "1" ]]; then
     echo -e "${WORNING} ${CYAN}All Bootstrap server offline, operation aborted.. ${NC}" && sleep 1
     echo -e ""
     exit
    fi
       
    bootstrap_index=$((${#richable[@]}-1))
    r=$(shuf -i 0-$bootstrap_index -n 1)
    indexb=${richable[$r]}
    BOOTSTRAP_ZIP="http://cdn-$indexb.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.tar.gz"
    BOOTSTRAP_ZIPFILE="${BOOTSTRAP_ZIP##*/}"
    
    pm2 stop watchdog > /dev/null 2>&1 && sleep 2
    echo -e "${ARROW} ${CYAN}Stopping Flux daemon service${NC}"
    sudo systemctl stop $COIN_NAME > /dev/null 2>&1 && sleep 2
    sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1

    if [[ -e /home/$USER/$CONFIG_DIR/blocks ]] && [[ -e /home/$USER/$CONFIG_DIR/chainstate ]]; then
        echo -e "${ARROW} ${CYAN}Cleaning...${NC}"
        rm -rf /home/$USER/$CONFIG_DIR/blocks /home/$USER/$CONFIG_DIR/chainstate /home/$USER/$CONFIG_DIR/determ_zelnodes
    fi 
    
    if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
    
     echo -e "${ARROW} ${YELLOW}Local bootstrap file detected...${NC}"
	
        if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then	
            
            echo -e "${ARROW} ${YELLOW}Checking if zip file is corrupted...${NC}"
	    
            if unzip -t $BOOTSTRAP_ZIPFILE | grep 'No errors' > /dev/null 2>&1
            then
                echo -e "${ARROW} ${CYAN}Bootstrap zip file is valid.............[${CHECK_MARK}${CYAN}]${NC}"
            else
                printf '\e[A\e[K'
                printf '\e[A\e[K'
                printf '\e[A\e[K'
                printf '\e[A\e[K'
                printf '\e[A\e[K'
                printf '\e[A\e[K'
                echo -e "${ARROW} ${CYAN}Bootstrap file is corrupted.............[${X_MARK}${CYAN}]${NC}"
                rm -rf $BOOTSTRAP_ZIPFILE
            fi
	    
        else	    
                check_tar "/home/$USER/$BOOTSTRAP_ZIPFILE"
        fi
	    
    fi


    if [ -f "/home/$USER/$BOOTSTRAP_ZIPFILE" ]; then
	
	
        if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
            echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
            unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
        else
            tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
            sleep 2  
        fi
	
    else

            CHOICE=$(
            whiptail --title "FLUXNODE INSTALLATION" --menu "Choose a method how to get bootstrap file" 10 47 2  \
                "1)" "Download from source build in script" \
                "2)" "Download from own source" 3>&2 2>&1 1>&3
            )


            case $CHOICE in
	    "1)")   
	        
	         DB_HIGHT=$(curl -SsL -m 10 http://cdn-$indexb.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.json | jq -r '.block_height')
		if [[ "$DB_HIGHT" == "" ]]; then
		  DB_HIGHT=$(curl -SsL -m 10 http://cdn-$indexb.runonflux.io/apps/fluxshare/getfile/flux_explorer_bootstrap.json | jq -r '.block_height')
		fi
		echo -e "${ARROW} ${CYAN}Flux daemon bootstrap height: ${GREEN}$DB_HIGHT${NC}"
	 	echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"
       		wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
	        tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR" 
		sleep 2



	    ;;
	    "2)")   
  		BOOTSTRAP_ZIP="$(whiptail --title "Flux daemon bootstrap setup" --inputbox "Enter your URL (zip, tar.gz)" 8 72 3>&1 1>&2 2>&3)"
		echo -e "${ARROW} ${YELLOW}Downloading File: ${GREEN}$BOOTSTRAP_ZIP ${NC}"		
		BOOTSTRAP_ZIPFILE="${BOOTSTRAP_ZIP##*/}"
		
		if [[ "$BOOTSTRAP_ZIPFILE" != *".zip"* ]]; then
                  BOOTSTRAP_ZIPFILE='flux_explorer_bootstrap.tar.gz'
                fi
		
		wget -O $BOOTSTRAP_ZIPFILE $BOOTSTRAP_ZIP -q --show-progress
		
	        if [[ "$BOOTSTRAP_ZIPFILE" == *".zip"* ]]; then
 		    echo -e "${ARROW} ${YELLOW}Unpacking wallet bootstrap please be patient...${NC}"
                    unzip -o $BOOTSTRAP_ZIPFILE -d /home/$USER/$CONFIG_DIR > /dev/null 2>&1
		else	       
		    tar_file_unpack "/home/$USER/$BOOTSTRAP_ZIPFILE" "/home/$USER/$CONFIG_DIR"
		    sleep 2
		fi
	    ;;
            esac

    fi
    
    
    if whiptail --yesno "Would you like remove bootstrap archive file?" 8 60; then
        rm -rf $BOOTSTRAP_ZIPFILE
    fi

    sudo systemctl start $COIN_NAME  > /dev/null 2>&1 && sleep 2
    NUM='35'
    MSG1='Starting Flux daemon service...'
    MSG2="${CYAN}........................[${CHECK_MARK}${CYAN}]${NC}"
    spinning_timer
    echo -e "" && echo -e ""
    pm2 restart flux > /dev/null 2>&1 && sleep 2
    pm2 start watchdog --watch > /dev/null 2>&1 && sleep 2
}


function install_node(){

echo -e "${GREEN}Module: Install FluxNode${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then
   echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
   echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
   echo
   exit
fi

if [[ $(lsb_release -cs) == "jammy" ]]; then
   echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
   echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
   echo
   exit
fi


if sudo docker run hello-world > /dev/null 2>&1
then
echo -e ""
else
echo -e "${WORNING}${CYAN}Docker is not working correct or is not installed.${NC}"
exit
fi


bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/${ROOT_BRANCH}/install_pro.sh)


}


function install_docker(){

echo -e "${GREEN}Module: Install Docker${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" != "root" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the root account use command 'sudo su -'.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi



if [[ $(lsb_release -d) != *Debian* && $(lsb_release -d) != *Ubuntu* ]]; then

    echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
    echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
    echo
    exit

fi

if [[ $(lsb_release -cs) == "jammy" ]]; then
   echo -e "${WORNING} ${CYAN}ERROR: ${RED}OS version not supported${NC}"
   echo -e "${WORNING} ${CYAN}Installation stopped...${NC}"
   echo
   exit
fi

if [[ -z "$usernew" ]]; then
  usernew="$(whiptail --title "MULTITOOLBOX $dversion" --inputbox "Enter your username" 8 72 3>&1 1>&2 2>&3)"
  usernew=$(awk '{print tolower($0)}' <<< "$usernew")
else
  echo -e "${PIN}${CYAN} Import docker user '$usernew' from environment variable............[${CHECK_MARK}${CYAN}]${NC}" && sleep 1
fi

echo -e "${ARROW} ${CYAN}New User: ${GREEN}${usernew}${NC}"
adduser --gecos "" "$usernew" 
usermod -aG sudo "$usernew" > /dev/null 2>&1  
echo -e "${ARROW} ${YELLOW}Update and upgrade system...${NC}"
apt update -y && apt upgrade -y 
if ! ufw version > /dev/null 2>&1
then
echo -e "${ARROW} ${YELLOW}Installing ufw firewall..${NC}"
sudo apt-get install -y ufw > /dev/null 2>&1
fi

cron_check=$(systemctl status cron 2> /dev/null | grep 'active' | wc -l)
if [[ "$cron_check" == "0" ]]; then
echo -e "${ARROW} ${YELLOW}Installing crontab...${NC}"
sudo apt-get install -y cron > /dev/null 2>&1
fi

echo -e "${ARROW} ${YELLOW}Installing docker...${NC}"
echo -e "${ARROW} ${CYAN}Architecture: ${GREEN}$(dpkg --print-architecture)${NC}"
           
if [[ -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
    sudo rm /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
fi

if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
    sudo rm /etc/apt/sources.list.d/docker.list > /dev/null 2>&1 
fi


if [[ $(lsb_release -d) = *Debian* ]]
then

sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
sudo apt-get update -y  > /dev/null 2>&1
sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1 
sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1
#curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - > /dev/null 2>&1
#sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /dev/null 2>&1
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
sudo apt-get update -y  > /dev/null 2>&1
sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1  

else

sudo apt-get remove docker docker-engine docker.io containerd runc -y > /dev/null 2>&1 
sudo apt-get -y install apt-transport-https ca-certificates > /dev/null 2>&1  
sudo apt-get -y install curl gnupg-agent software-properties-common > /dev/null 2>&1  

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - > /dev/null 2>&1
#sudo add-apt-repository -y "deb [arch=amd64,arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /dev/null 2>&1
sudo apt-get update -y  > /dev/null 2>&1
sudo apt-get install docker-ce docker-ce-cli containerd.io -y > /dev/null 2>&1

fi

# echo -e "${YELLOW}Creating docker group..${NC}"
# groupadd docker
echo -e "${ARROW} ${YELLOW}Adding $usernew to docker group...${NC}"
adduser "$usernew" docker 
echo -e "${NC}"
echo -e "${YELLOW}=====================================================${NC}"
echo -e "${YELLOW}Running through some checks...${NC}"
echo -e "${YELLOW}=====================================================${NC}"

if sudo docker run hello-world > /dev/null 2>&1  
then
	echo -e "${CHECK_MARK} ${CYAN}Docker is installed${NC}"
else
	echo -e "${X_MARK} ${CYAN}Docker did not installed${NC}"
fi

if [[ $(getent group docker | grep "$usernew") ]] 
then
	echo -e "${CHECK_MARK} ${CYAN}User $usernew is member of 'docker'${NC}"
else
	echo -e "${X_MARK} ${CYAN}User $usernew is not member of 'docker'${NC}"
fi

echo -e "${YELLOW}=====================================================${NC}"
echo -e "${NC}"
read -p "Would you like switch to user account Y/N?" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]]
then
su - $usernew
fi

}

function daemon_reconfiguration()
{

echo -e "${GREEN}Module: Flux Daemon Reconfiguration${NC}"
echo -e "${YELLOW}================================================================${NC}"

if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
fi

config_veryfity

echo
echo -e "${ARROW} ${YELLOW}Fill in all the fields that you want to replace${NC}"
sleep 4
skip_change='3'
zelnodeprivkey="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode Identity Key generated by your Zelcore" 8 72 3>&1 1>&2 2>&3)"
sleep 1
zelnodeoutpoint="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode Collateral TX ID" 8 72 3>&1 1>&2 2>&3)"
sleep 1
zelnodeindex="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode Output Index" 8 60 3>&1 1>&2 2>&3)"
sleep 1
#externalip="$(whiptail --title "Flux daemon reconfiguration" --inputbox "Enter your FluxNode IP" 8 60 3>&1 1>&2 2>&3)"
#sleep 1

if [[ "$zelnodeprivkey" == "" ]]; then
skip_change=$((skip_change-1))
echo -e "${ARROW} ${CYAN}Replace FluxNode identity key skipped....................[${CHECK_MARK}${CYAN}]${NC}"
fi

if [[ "$zelnodeoutpoint" == "" ]]; then
skip_change=$((skip_change-1))
echo -e "${ARROW} ${CYAN}Replace FluxNode outpoint skipped ..................[${CHECK_MARK}${CYAN}]${NC}"
fi

if [[ "$zelnodeindex" == "" ]]; then
skip_change=$((skip_change-1))
echo -e "${ARROW} ${CYAN}Replace FluxNode index skipped......................[${CHECK_MARK}${CYAN}]${NC}"
fi

#if [[ "$externalip" == "" ]]; then
#skip_change=$((skip_change-1))
#echo -e "${ARROW} ${CYAN}Replace FluxNode IP skipped.........................[${CHECK_MARK}${CYAN}]${NC}"
#fi


if [[ "$skip_change" == "0" ]]; then
echo -e "${ARROW} ${YELLOW}All fields are empty changes skipped...${NC}"
echo
exit
fi

echo -e "${ARROW} ${CYAN}Stopping Flux daemon service...${NC}"
sudo systemctl stop $COIN_NAME  > /dev/null 2>&1 && sleep 2
sudo fuser -k 16125/tcp > /dev/null 2>&1


if [[ "$zelnodeprivkey" != "" ]]; then

if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
echo -e "${ARROW} ${CYAN}Replace FluxNode identity key skipped....................[${CHECK_MARK}${CYAN}]${NC}"
        else
        sed -i "s/$(grep -e zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeprivkey=$zelnodeprivkey/" ~/$CONFIG_DIR/$CONFIG_FILE
                if [[ "zelnodeprivkey=$zelnodeprivkey" == $(grep -w zelnodeprivkey ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
                        echo -e "${ARROW} ${CYAN}FluxNode identity key replaced successful................[${CHECK_MARK}${CYAN}]${NC}"			
                fi
fi

fi

if [[ "$zelnodeoutpoint" != "" ]]; then

if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
echo -e "${ARROW} ${CYAN}Replace FluxNode outpoint skipped ..................[${CHECK_MARK}${CYAN}]${NC}"
        else
        sed -i "s/$(grep -e zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeoutpoint=$zelnodeoutpoint/" ~/$CONFIG_DIR/$CONFIG_FILE
                if [[ "zelnodeoutpoint=$zelnodeoutpoint" == $(grep -w zelnodeoutpoint ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
                        echo -e "${ARROW} ${CYAN}FluxNode outpoint replaced successful...............[${CHECK_MARK}${CYAN}]${NC}"
                fi
fi

fi

if [[ "$zelnodeindex" != "" ]]; then

if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
echo -e "${ARROW} ${CYAN}Replace FluxNode index skipped......................[${CHECK_MARK}${CYAN}]${NC}"
        else
        sed -i "s/$(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE)/zelnodeindex=$zelnodeindex/" ~/$CONFIG_DIR/$CONFIG_FILE
                if [[ "zelnodeindex=$zelnodeindex" == $(grep -w zelnodeindex ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
                        echo -e "${ARROW} ${CYAN}FluxNode index replaced successful..................[${CHECK_MARK}${CYAN}]${NC}"
			
                fi
fi

fi

#if [[ "$externalip" != "" ]]; then

#if [[ "externalip=$externalip" == $(grep -w externalip ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
#echo -e "${ARROW} ${CYAN}Replace FluxNode IP skipped.........................[${CHECK_MARK}${CYAN}]${NC}"
       # else
       # sed -i "s/$(grep -w externalip ~/$CONFIG_DIR/$CONFIG_FILE)/externalip=$externalip/" ~/$CONFIG_DIR/$CONFIG_FILE
                #if [[ "externalip=$externalip" == $(grep -w externalip ~/$CONFIG_DIR/$CONFIG_FILE) ]]; then
                       # echo -e "${ARROW} ${CYAN}FluxNode IP replaced successful.....................[${CHECK_MARK}${CYAN}]${NC}"
			
               # fi
#fi
#fi

pm2 restart flux > /dev/null 2>&1
sudo systemctl start $COIN_NAME  > /dev/null 2>&1 && sleep 2
NUM='35'
MSG1='Restarting daemon service...'
MSG2="${CYAN}........................[${CHECK_MARK}${CYAN}]${NC}"
spinning_timer
echo -e "" && echo -e ""

}

function create_service_scripts() {

echo -e "${ARROW} ${CYAN}Creating Flux daemon service scripts...${NC}" && sleep 1
sudo touch /home/$USER/start_daemon_service.sh
sudo chown $USER:$USER /home/$USER/start_daemon_service.sh
    cat <<'EOF' > /home/$USER/start_daemon_service.sh
#!/bin/bash
#color codes
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'
#emoji codes
BOOK="${RED}\xF0\x9F\x93\x8B${NC}"
WORNING="${RED}\xF0\x9F\x9A\xA8${NC}"
sleep 2
echo -e "${BOOK} ${CYAN}Pre-start process starting...${NC}"
echo -e "${BOOK} ${CYAN}Checking if benchmark or daemon is running${NC}"
bench_status_pind=$(pgrep fluxbenchd)
daemon_status_pind=$(pgrep fluxd)
if [[ "$bench_status_pind" == "" && "$daemon_status_pind" == "" ]]; then
echo -e "${BOOK} ${CYAN}No running instance detected...${NC}"
else
if [[ "$bench_status_pind" != "" ]]; then
echo -e "${WORNING} Running benchmark process detected${NC}"
echo -e "${WORNING} Killing benchmark...${NC}"
sudo killall -9 fluxbenchd > /dev/null 2>&1  && sleep 2
fi
if [[ "$daemon_status_pind" != "" ]]; then
echo -e "${WORNING} Running daemon process detected${NC}"
echo -e "${WORNING} Killing daemon...${NC}"
sudo killall -9 fluxd > /dev/null 2>&1  && sleep 2
fi
sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
fi
bench_status_pind=$(pgrep zelbenchd)
daemon_status_pind=$(pgrep zelcashd)
if [[ "$bench_status_pind" == "" && "$daemon_status_pind" == "" ]]; then
echo -e "${BOOK} ${CYAN}No running instance detected...${NC}"
else
if [[ "$bench_status_pind" != "" ]]; then
echo -e "${WORNING} Running benchmark process detected${NC}"
echo -e "${WORNING} Killing benchmark...${NC}"
sudo killall -9 zelbenchd > /dev/null 2>&1  && sleep 2
fi
if [[ "$daemon_status_pind" != "" ]]; then
echo -e "${WORNING} Running daemon process detected${NC}"
echo -e "${WORNING} Killing daemon...${NC}"
sudo killall -9 zelcashd > /dev/null 2>&1  && sleep 2
fi
sudo fuser -k 16125/tcp > /dev/null 2>&1 && sleep 1
fi
if [[ -f /usr/local/bin/fluxd ]]; then
bash -c "fluxd"
exit
else
bash -c "zelcashd"
exit
fi
EOF


sudo touch /home/$USER/stop_daemon_service.sh
sudo chown $USER:$USER /home/$USER/stop_daemon_service.sh
    cat <<'EOF' > /home/$USER/stop_daemon_service.sh
#!/bin/bash
if [[ -f /usr/local/bin/flux-cli ]]; then
bash -c "flux-cli stop"
else
bash -c "zelcash-cli stop"
fi
exit
EOF

echo -e "${ARROW} ${CYAN}Setting scripts permissions...${NC}" && sleep 1
sudo chmod +x /home/$USER/stop_daemon_service.sh
sudo chmod +x /home/$USER/start_daemon_service.sh
echo -e "${ARROW} ${CYAN}Reloading service config...${NC}" && sleep 1
sudo systemctl daemon-reload > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Starting Flux daemon....${NC}" && sleep 1
sudo systemctl start zelcash > /dev/null 2>&1
echo -e ""
}

function create_service() {

 echo -e "${GREEN}Module: Flux Daemon service creator${NC}"
 echo -e "${YELLOW}================================================================${NC}"
 
if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
 fi 
 
echo -e ""
echo -e "${ARROW} ${CYAN}Cleaning...${NC}" && sleep 1
sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 2
sudo rm -rf /home/$USER/start_daemon_service.sh > /dev/null 2>&1  
sudo rm -rf /home/$USER/stop_daemon_service.sh > /dev/null 2>&1 
sudo rm -rf /home/$USER/start_zelcash_service.sh > /dev/null 2>&1  
sudo rm -rf /home/$USER/stop_zelcash_service.sh > /dev/null 2>&1 
sudo rm -rf /etc/systemd/system/zelcash.service > /dev/null 2>&1
    
echo -e "${ARROW} ${CYAN}Creating Flux daemon service...${NC}" && sleep 1
sudo touch /etc/systemd/system/zelcash.service
sudo chown $USER:$USER /etc/systemd/system/zelcash.service
cat << EOF > /etc/systemd/system/zelcash.service
[Unit]
Description=Flux daemon service
After=network.target
[Service]
Type=forking
User=$USER
Group=$USER
ExecStart=/home/$USER/start_daemon_service.sh
ExecStop=-/home/$USER/stop_daemon_service.sh
Restart=always
RestartSec=10
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=15s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
    sudo chown root:root /etc/systemd/system/zelcash.service
}

function replace_kadena {

 while true
  do
   KDA_A=$(whiptail --inputbox "Please enter your Kadena address from Zelcore" 8 85 3>&1 1>&2 2>&3)
   kda_address="kadena:$KDA_A?chainid=0"
   if [[ "$KDA_A" == "" ]]; then
     echo -e "${WORNING} ${CYAN}Kadena address can't be empty string, operation aborted...${NC}"
     echo -e ""
     exit
   fi
   break
 done


if [[ $(cat /home/$USER/zelflux/config/userconfig.js | grep "kadena") != "" ]]; then

  sed -i "s/$(grep -e kadena /home/$USER/zelflux/config/userconfig.js)/kadena: '$kda_address',/" /home/$USER/zelflux/config/userconfig.js

  if [[ $(grep -w $KDA_A /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
     echo -e "${ARROW} ${CYAN}Kadena address replaced successfully...................[${CHECK_MARK}${CYAN}]${NC}"
  fi

else

   insertAfter "/home/$USER/zelflux/config/userconfig.js" "zelid" "kadena: '$kda_address',"
   echo -e "${ARROW} ${CYAN}Kadena address set successfully........................[${CHECK_MARK}${CYAN}]${NC}"

fi


}


function replace_zelid() {

while true
  do

    new_zelid="$(whiptail --title "MULTITOOLBOX" --inputbox "Enter your ZEL ID from ZelCore (Apps -> Zel ID (CLICK QR CODE)) " 8 72 3>&1 1>&2 2>&3)"

    if [ $(printf "%s" "$new_zelid" | wc -c) -eq "34" ] || [ $(printf "%s" "$new_zelid" | wc -c) -eq "33" ]; then
      string_limit_check_mark "Zel ID is valid..........................................."
      break
    else
      string_limit_x_mark "Zel ID is not valid try again..........................................."
      sleep 2
   fi

  done

  if [[ $(grep -w $new_zelid /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
     echo -e "${ARROW} ${CYAN}Replace ZEL ID skipped............................[${CHECK_MARK}${CYAN}]${NC}"
   else
        sed -i "s/$(grep -e zelid /home/$USER/zelflux/config/userconfig.js)/zelid:'$new_zelid',/" /home/$USER/zelflux/config/userconfig.js

        if [[ $(grep -w $new_zelid /home/$USER/zelflux/config/userconfig.js) != "" ]]; then
                        echo -e "${ARROW} ${CYAN}ZEL ID replaced successful........................[${CHECK_MARK}${CYAN}]${NC}"
        fi
   fi

}


function fluxos_reconfiguration {

 echo -e "${GREEN}Module: FluxOS reconfiguration${NC}"
 echo -e "${YELLOW}================================================================${NC}"

 if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
 fi

 if ! [[ -f /home/$USER/zelflux/config/userconfig.js ]]; then
   echo -e "${WORNING} ${CYAN}FluxOS userconfig.js not exist, operation aborted${NC}"
   echo -e ""
   exit
 fi


 CHOICE=$(
 whiptail --title "FluxOS Configuration" --menu "Make your choice" 15 40 6 \
 "1)" "Replace ZELID"   \
 "2)" "Add/Replace kadena address"  3>&2 2>&1 1>&3
 )


case $CHOICE in
        "1)")
         replace_zelid
        ;;
        "2)")
         replace_kadena
        ;;
esac

}


 function install_watchtower(){
 
 echo -e "${GREEN}Module: Install flux_watchtower for docker images autoupdate${NC}"
 echo -e "${YELLOW}================================================================${NC}"
 
if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
 fi 
 
echo -e ""
echo -e "${ARROW} ${CYAN}Checking if flux_watchtower is installed....${NC}"
apps_check=$(docker ps | grep "flux_watchtower")

if [[ "$apps_check" != "" ]]; then
echo -e "${ARROW} ${CYAN}Stopping flux_watchtower...${NC}"
docker stop flux_watchtower > /dev/null 2>&1
sleep 2
echo -e "${ARROW} ${CYAN}Removing flux_watchtower...${NC}"
docker rm flux_watchtower > /dev/null 2>&1
fi

echo -e "${ARROW} ${CYAN}Downloading containrrr/watchtower image...${NC}"
docker pull containrrr/watchtower:latest > /dev/null 2>&1
echo -e "${ARROW} ${CYAN}Starting containrrr/watchtower...${NC}"
random=$(shuf -i 7500-35000 -n 1)
echo -e "${ARROW} ${CYAN}Interval: ${GREEN} $random sec.${NC}"
apps_id=$(docker run -d \
--restart unless-stopped \
--name flux_watchtower \
-v /var/run/docker.sock:/var/run/docker.sock \
containrrr/watchtower \
--cleanup --interval $random 2> /dev/null) 
if [[ $apps_id =~ ^[[:alnum:]]+$ ]]; then
echo -e "${ARROW} ${CYAN}flux_watchtower installed successful, id: ${GREEN}$apps_id${NC}"
else
echo -e "${ARROW} ${CYAN}flux_watchtower installion failed...${NC}"
fi
 
 }
 
 
 function mongod_db_fix() {
  echo -e "${GREEN}Module: Recover corrupted MongoDB database${NC}"
  echo -e "${YELLOW}================================================================${NC}"
 
 if [[ "$USER" == "root" || "$USER" == "ubuntu" || "$USER" == "admin" ]]; then
    echo -e "${CYAN}You are currently logged in as ${GREEN}$USER${NC}"
    echo -e "${CYAN}Please switch to the user account.${NC}"
    echo -e "${YELLOW}================================================================${NC}"
    echo -e "${NC}"
    exit
  fi 
 
  echo -e ""  
  echo -e "${WORNING} ${CYAN}Stopping mongod service ${NC}" && sleep 1
  sudo systemctl stop mongod
  echo -e "${WORNING} ${CYAN}Fix for corrupted DB ${NC}" && sleep 1
  sudo -u mongodb mongod --dbpath /var/lib/mongodb --repair
  echo -e "${WORNING} ${CYAN}Fix for bad privilege ${NC}" && sleep 1
  sudo chown -R mongodb:mongodb /var/lib/mongodb > /dev/null 2>&1
  sudo chown mongodb:mongodb /tmp/mongodb-27017.sock > /dev/null 2>&1
  echo -e "${WORNING} ${CYAN}Starting mongod service ${NC}" && sleep 1
  sudo systemctl start mongod
  echo -e ""
  
 
 }


if ! figlet -v > /dev/null 2>&1
then
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y figlet > /dev/null 2>&1
fi

if ! pv -V > /dev/null 2>&1
then
sudo apt-get install -y pv > /dev/null 2>&1
fi

if ! gzip -V > /dev/null 2>&1
then
sudo apt-get install -y gzip > /dev/null 2>&1
fi

if ! zip -v > /dev/null 2>&1
then
sudo apt-get install -y zip > /dev/null 2>&1
fi

if ! whiptail -v > /dev/null 2>&1
then
sudo apt-get install -y whiptail > /dev/null 2>&1
fi

if [[ $(cat /etc/bash.bashrc | grep 'multitoolbox' | wc -l) == "0" ]]; then
echo "alias multitoolbox='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox.sh)'" | sudo tee -a /etc/bash.bashrc
echo "alias multitoolbox_testnet='bash -i <(curl -s https://raw.githubusercontent.com/RunOnFlux/fluxnode-multitool/master/multitoolbox_testnet.sh)'" | sudo tee -a /etc/bash.bashrc
source /etc/bash.bashrc
fi

if ! wget --version > /dev/null 2>&1 ; then
   sudo apt install -y wget > /dev/null 2>&1 && sleep 2
fi


while [ condition ]
do
	clear
	sleep 1
	echo -e "${BLUE}"
	figlet -f slant "Multitoolbox"
	echo -e "${YELLOW}================================================================${NC}"
	echo -e "${GREEN}Version: $dversion${NC} - (FluxBox v1.2 - Aug 17, 2022)"
	echo -e "${GREEN}OS: Ubuntu 16/18/19/20, Debian 9/10 ${NC}"
	echo -e "${GREEN}Created by: X4MiLX from Flux's team${NC}"
	echo -e "${GREEN}Special thanks to dk808, CryptoWrench && jriggs28${NC}"
  echo -e "\n"  
  echo -e "FluxBox Install Run Steps 1-4 In Sequence"

	echo -e "${YELLOW}======================== BASE OPTIONS =============================${NC}"  
	echo -e "${CYAN}1  - Install FluxNode${NC}"
  echo -e "${CYAN}2  - Restore Flux blockchain from bootstrap${NC}"
  echo -e "${CYAN}3  - Multinode configuration with UPNP communication (Needs Router with UPNP support)  ${NC}"
	echo -e "${CYAN}4  - FluxNode analyzer and fixer${NC}"

  echo -e "${YELLOW}======================== EXTRA OPTIONS =============================${NC}"
	echo -e "${CYAN}5  - Install watchdog for FluxNode${NC}"	
	echo -e "${CYAN}6  - Create FluxNode installation config file${NC}"
	echo -e "${CYAN}7  - Re-install FluxOS${NC}"
	echo -e "${CYAN}8  - Flux Daemon Reconfiguration${NC}"
	echo -e "${CYAN}9  - Create Flux daemon service ( for old nodes )${NC}"
	echo -e "${CYAN}10 - Create Self-hosting cron ip service ${NC}"
	echo -e "${CYAN}11 - Replace Zel ID ${NC}"
	echo -e "${CYAN}12 - Install fluxwatchtower for docker images autoupdate${NC}"
	echo -e "${CYAN}13 - Recover corrupted MongoDB database${NC}"	

  echo -e "\n ** Enter Option 14 to return back to main FluxBox menu"
	echo -e "${CYAN}14 - Back to FluxBox main menu  ${NC}"
	echo -e "${YELLOW}================================================================${NC}"

	read -rp "Pick an option and hit ENTER: "

	  case "$REPLY" in

	 1) 
	    clear
	    sleep 1
	    install_node
	 ;;
	 2)  
	    clear
	    sleep 1
	    flux_daemon_bootstrap     
	 ;; 
	 3)
	    clear
	    sleep 1
	    multinode
	    echo -e ""
	  ;;
	 4)     
	    clear
	    sleep 1
	    analyzer_and_fixer
	 ;;
	  5)  
	    clear
	    sleep 1
	    install_watchdog   
	 ;;	 
	  6)
	    clear
	    sleep 1
	    create_config
	 ;;
	   7)
	    clear
	    sleep 1
	    install_flux
	 ;;
	 8)
	   clear
	   sleep 1
	   daemon_reconfiguration	   
	 ;;	 
	 9)
	  clear
	  sleep 1
	  create_service
	  create_service_scripts
	 ;;
	 
	  10)
	  clear
	  sleep 1
	  selfhosting
	 ;;
	 
	   11)
	  clear
	  sleep 1
	  replace_zelid
	  echo -e ""
	 ;;
	 
	    12)
	  clear
	  sleep 1
	  install_watchtower
	  echo -e ""
	 ;;
	 
	     13)
	  clear
	  sleep 1
	  mongod_db_fix
	  echo -e ""
	 ;;
		 
	 14)
	    start
	 ;;

	    esac

  echo -e "${WHITE}<<<<< PRESS ENTER TO RETURN TO MENU >>>>>${NC}"
	read -rp ""
done

