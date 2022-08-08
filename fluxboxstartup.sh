#!/bin/bash

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE="\\033[1;97m"
NC='\033[0m'

# function definitions

function setPermissions() {
  sudo apt install ifupdown -y
  mv ~/flux-multitool/grub.config /etc/default/grub
  sudo update-grub

  chmod u+x ~/flux-multitool/resetnetwork.sh
  chmod +x ~/flux-multitool/resetnetwork.sh
}

function showIntro() {
 clear
 cat ~/flux-multitool/fluxart.txt
 sleep 2
 clear

 echo -e "${BLUE} ======================== WELCOME TO FLUXBOX V1.1 ======================="
 echo -e "${CYAN} ======================== www.fluxnodestore.com =========================\r\n"

 echo -e "FluxBox Name:\t$HOSTNAME"
 echo -e "IP Address:\t$(hostname -I)"
 echo -e "Public IP:\t$(dig +short myip.opendns.com @resolver1.opendns.com)"

 echo -e "\n"
 echo -e "${YELLOW} ======================= PROCESSOR INFORMATION ==========================${WHITE}"
 lscpu | grep -E "Model name|^CPU\(s\):|Architecture:|Thread\(s\) per core"

 echo -e "\r\n${YELLOW} ======================= MEMORY INFORMATION =============================${WHITE}"
 cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable"

 echo -e "\r\n${YELLOW} ======================= STORAGE INFORMATION ============================${WHITE}"
 lsblk | grep -E "^.*disk"

 echo -e "${WHITE}\n *** For Help and Support - fluxnodestore@gmail.com ***" 
 echo -e "${WHITE} *** NOTE: Type ${CYAN}\"start\"${WHITE} from the command prompt to get back to this menu at any time ***\n" 
}

function restartNic() {
 service docker stop
 sudo /etc/init.d/networking restart
 service docker start
}

function installRestartCron() {
  crontab -l > mycron.temp
  echo "0 */12 * * * /home/fluxbox/flux-multitool/resetnetwork.sh" >> mycron.temp
  crontab mycron.temp
  rm mycron.temp
}

function showMenu() {

  echo -e "${SEA} ========================= FLUX BOX MAIN MENU ===========================${WHITE}"  
  echo -e " 1. Launch FluxNode Setup"
  echo -e " 2. Change Password"
  echo -e " 3. Rename Box"
  echo -e " 4. Restart FluxBox"
  echo -e " 5. Setup Wifi"
  echo -e " 6. Refresh Network Interface"
  echo -e " 7. Install Automated Network Refresh Job"

  echo -e "\n"

  read -rp "Please select an option and hit ENTER: "

  case "$REPLY" in
   1)
      clear
      sleep 1
      launchToolBox
      exit 0
   ;;
   2)
      clear
      sleep 1
      passwd
   ;;
   3)
     clear

     echo "Current Name: $HOSTNAME"
     read -p "Enter new name : " newName
     echo -e "Setting to $newName... Please wait a moment"
     sudo hostnamectl set-hostname $newName
     sleep 15

     export HOSTNAME=$newName
     hostnamectl | grep "Static hostname"

     echo -e "\n Success, new name is $HOSTNAME"
     sleep 3
   ;;
   4)
     read -p "Would you like to restart Y/N?" -n 1 -r
     echo -e "${NC}"

     if [[ $REPLY =~ ^[Yy]$ ]]
     then
      clear
      echo "Restarting FluxBox in..."

      for ((counter=10; counter > 0; counter--))
      do
        echo $counter
        sleep 1
      done

      sudo shutdown -r now
    fi
   ;;
   5)
     clear
     sudo python3 ~/flux-multitool/easywifi.py
   ;;
   6)
    clear
    echo "Refreshing Network Interface..."
    service docker restart    
  ;;
  7)
   clear
   echo "Installing crontab restart schedule"
   installRestartCron
  esac

  showIntro
  showMenu
}

function launchToolBox() {

  echo -e "\r\n${YELLOW} ============================= IMPORTANT ================================${WHITE}"
  echo -e " Before you proceed, please ensure you have the following information from your Zelcore Wallet\n"
  echo -e " ${BLUE}1. You have sent at least 1000 FLUX from your Zelcore FLUX Wallet to ITSELF (Receiving Address)"
  echo -e " 2. Your Zelcore Id (Apps -> Zelcore ID -> Tap QR Code)"
  echo -e " 3. Your FluxNode Identity Key"
  echo -e " 4. Your FluxNode Collateral TX ID"
  echo -e " 5. Your FluxNode Output Index"
  echo -e " 6. Enable UpnP on Your Router so traffic can be re-directed on the proper port to your node"
  echo -e "${NC}\n${WHITE}"

  read -p "Would you like to continue Y/N? " -n 1 -r

  echo -e "${NC}"

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
   echo "Launching MultiToolBox, please wait...."
   
   sleep 3
   ~/flux-multitool/multitoolbox.sh
  else
   showIntro
   showMenu
  fi  
}

# Allow port 9090
sudo ufw allow 9090

# Set basic perimssions on scripts
setPermissions

# Start Process
showIntro

# Show Menu
showMenu
