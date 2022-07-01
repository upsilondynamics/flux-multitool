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
    connectedNetworks = subprocess.run(['nmcli', "d", "|", "grep", "connected"], stdout=subprocess.PIPE)
    print(connectedNetworks)

    print("\n")
    print("=======================================")
    print("                  MENU                 ")
    print("=======================================")
    print("1) Connect to WIFI")    
    print("2) Disconnect from WIFI")
    print("3) Exit back to menu")
    
    print("\n")
    choice = input(": ")
    if choice == "1":
        scan_networks()

        network = input("Enter SSID: ")
        result = subprocess.run(['nmcli', "d", "wifi", "connect", network], stdout=subprocess.PIPE)
        print(result.stdout.decode('utf-8'))

    elif choice == "2":
        scan_networks()

        result = subprocess.run(['nmcli', "c"], stdout=subprocess.PIPE)
        print(result.stdout.decode('utf-8'))
        contodel = str(input("Enter SSID: "))
        result2 = subprocess.run(['nmcli', "connection", "delete", contodel], stdout=subprocess.PIPE)
        print(result2.stdout.decode('utf-8'))

    elif choice == "2":
        exit()

    else:
        print("Invalid choice!")