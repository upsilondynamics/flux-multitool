import os
import time
import subprocess
from shlex import split
from getpass import getpass
from shutil import which
from sys import exit
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def scan_networks():
    result = subprocess.run(['nmcli', "d", "wifi", "list"], stdout=subprocess.PIPE)
    print(result.stdout.decode('utf-8'))

if which("nmcli") is None:
    print(bcolors.FAIL+"easywifi requires NetworkManager, please install it before using this!"+bcolors.ENDC)
    exit()

def getssid(netname):
    p1 = subprocess.Popen(split("nmcli --fields NAME,UUID c"), stdout=subprocess.PIPE)
    p2 = subprocess.Popen(split("grep -i "+str(netname)), stdin=p1.stdout, stdout=subprocess.PIPE)
    ss=p2.communicate()[0].decode('utf-8')
    return str(ss.split()[1])

while True:
    os.system('clear')

    print(bcolors.OKBLUE)
    print("=======================================")
    print("              WIFI SETUP               ")
    print("=======================================")
    print(bcolors.ENDC)

    result = subprocess.run(['nmcli', "d"], stdout=subprocess.PIPE)
    print(result.stdout.decode('utf-8'))

    print(bcolors.OKBLUE)
    print("=======================================")
    print("                  MENU                 ")
    print("=======================================")
    print(bcolors.ENDC)
    print("1) Connect to WIFI")    
    print("2) Disconnect from WIFI")
    print("3) Exit back to menu")
    
    print("\n")
    choice = input(": ")
    if choice == "1":
        scan_networks()

        network = input("Enter SSID: ")
        password = getpass()
        result = subprocess.run(['nmcli', "d", "wifi", "connect", network, "password", str(password)], stdout=subprocess.PIPE)
        print(result.stdout.decode('utf-8'))
        
        result = subprocess.run(['nmcli', "connection", "modify", network, "ipv6.method", "disabled"], stdout=subprocess.PIPE)
        # sudo dhclient -v wlxb4b024340e7a

        result = subprocess.run(['dhclient', "-v", device], stdout=subprocess.PIPE)

        time.sleep(3)
        
    elif choice == "2":
        scan_networks()

        result = subprocess.run(['nmcli', "c"], stdout=subprocess.PIPE)
        print(result.stdout.decode('utf-8'))
        contodel = str(input("Enter SSID: "))
        result2 = subprocess.run(['nmcli', "connection", "delete", contodel], stdout=subprocess.PIPE)
        print(result2.stdout.decode('utf-8'))
        time.sleep(3)

    elif choice == "3":
        exit()

    else:
        print("Invalid choice!")
