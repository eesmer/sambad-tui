#!/bin/bash
#buildnumber:21052025

if ! [ -x "$(command -v whiptail)" ]; then
apt -y install whiptail
fi
if ! [ -x "$(command -v netstat)" ]; then
apt -y install net-tools
fi
if ! [ -x "$(command -v nmap)" ]; then
apt -y install nmap
fi

RESET=$(tput sgr0)
BOLD=$(tput bold)
UNDERLINE=$(tput smul)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

print_section() {
  local title="$1"
  local color="$2"
  echo "${BOLD}${color}${title}${RESET}"
}

SERVER=$(ip r |grep link |grep src |cut -d'/' -f2 |cut -d'c' -f3 |cut -d' ' -f2)
ZONE=$(samba-tool domain info $SERVER |grep Domain |cut -d':' -f2 |cut -d' ' -f2)

samba-tool domain passwordsettings set --min-pwd-age=0 # for Password_Change_Next_Logon to work after create user

function pause(){
local message="$@"
[ -z $message ] && message="Press Enter to continue"
read -p "$message" readEnterKey
}

function show_menu(){
date
echo "   |-------------------------------------------------------------------------------------------|"
print_section "     SambaAD-tui v2 " "$CYAN"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | User Management           | Group Management | OU Management      | DNS Management        |"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | 1.Create User             | 11.Create Group  | 21.Create OU       | 31.Add DNS Record     |"
echo "   | 2.Delete User             | 12.Delete Group  | 22.Delete OU       | 32.Delete DNS Record  |"
echo "   | 3.Disable/Enable User     | 13.Add Member    | 23.Move User to OU | 33.DNS Records List   |"
echo "   | 4.Set Expiration          | 14.Remove Member | 24.OU List                                 |"
echo "   | 5.Change Password         | 15.Group List    | 25.Rename OU                               |"
echo "   | 6.Change Pass.Next Logon  | 16.Member List   |                                            |"
echo "   | 7.User List               |                  |                                            |"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | FSMO & Role Management    | DC Management    | LOG Viewer                                 |"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | 51.Transfer FSMO Role     | 55.Show DC Hosts | 90.LOG Viewer                              |"
echo "   | 52.Seize FSMO Role        | 56.Demote DC     |                                            |"
echo "   | 53.Seize DNS Role         |                                                               |"
echo "   | ------------------------  |                                                               |"
echo "   | 82.Show Roles             |                                                               |"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | Domain Settings           | Troubleshooting & Maintenance                                 |"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | 71.Show Password Settings | 81.Database Check   86.Listening Ports                        |"
echo "   | 72.Set Password Length    | 82.Show FSMO Roles  87.DNS Status                             |"
echo "   | 73.Set Password History   | 83.Show Processes   88.Query DNS Records                      |"
echo "   | 74.Set Password Age       | 84.Domain Info                                                |"
echo "   | 75.Password Complexity    | 85.Repl.Status                                                |"
echo "   |-------------------------------------------------------------------------------------------|"
echo "   | ${BOLD}${RED}${UNDERLINE}99.Exit${RESET} | 0.About                                                                         |"
echo "   |-------------------------------------------------------------------------------------------|"
}

function create_user(){
echo ""
echo "::Create User::"
echo "---------------"
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
USER_NAME=$(whiptail --title "User Name" --inputbox "Please enter the Name" 10 60  3>&1 1>&2 2>&3)
USER_SURNAME=$(whiptail --title "User Surname" --inputbox "Please enter the Last Name" 10 60  3>&1 1>&2 2>&3)
USER_EMAIL=$(whiptail --title "Email Address" --inputbox "Please enter the E-Mail Address" 10 60  3>&1 1>&2 2>&3)
USER_DEPARTMENT=$(whiptail --title "User Department" --inputbox "Please enter the Department" 10 60  3>&1 1>&2 2>&3)
USER_PASSWORD=$(whiptail --title "User Password" --passwordbox "Please enter the Password" 10 60  3>&1 1>&2 2>&3)
samba-tool user create $DOMAIN_USER "TempPassword1" --given-name=$USER_NAME --surname=$USER_SURNAME --mail-address=$USER_EMAIL --department=$USER_DEPARTMENT
samba-tool user setpassword --newpassword="$USER_PASSWORD" --must-change-at-next-login $DOMAIN_USER
pause
}

function delete_user(){
echo ""
echo "::Delete User::"
echo "---------------"
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool user delete $DOMAIN_USER
pause
}

function disable-enable_user(){
echo ""
echo "::Enable/Disable User::"
echo "-----------------------"
choice=$(whiptail --title "Enable/Disable" --radiolist "Choose:"     10 25 5 \
        "Enable" "" on \
        "Disable" "" off 3>&1 1>&2 2>&3)
case $choice in
Enable)
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool user enable $DOMAIN_USER
;;
Disable)
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool user disable $DOMAIN_USER && CONTINUE=true

if [ "$CONTINUE" == true ]
then
echo "Disabled user $DOMAIN_USER"
fi
;;
*)
;;
esac
pause
}

function set_expiration(){
echo ""
echo "::Set Expiration::"
echo "------------------"
CHOICE=$(whiptail --title "Set Expiration" --radiolist "Choose:"     10 25 5 \
»···"SetExpiration" "" on \
»···"NoExpiry" "" off 3>&1 1>&2 2>&3)
case $CHOICE in
SetExpiration)
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
DAYS=$(whiptail --title "Expiry Day" --inputbox "Please enter the number of days" 10 60  3>&1 1>&2 2>&3)
samba-tool user setexpiry --days=$DAYS $DOMAIN_USER
;;
NoExpiry)
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool user setexpiry --noexpiry $DOMAIN_USER
;;
*)
;;
esac
pause
}

function change_password(){
echo ""
echo "::Change Password::"
echo "-------------------"
DOMAIN_USER=$(whiptail --title "Change Password" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --title "Set Password" --passwordbox "Please enter the password you want to assign" 10 60  3>&1 1>&2 2>&3)
samba-tool user setpassword --newpassword="$PASSWORD" $DOMAIN_USER
pause
}

function change_pass_nextlogon(){
echo ""
echo "::Change Password at Next Logon::"
echo "---------------------------------"
DOMAIN_USER=$(whiptail --title "Change Password at Next Logon" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --title "Set Password" --passwordbox "Please enter the Temporary Password" 10 60  3>&1 1>&2 2>&3)
samba-tool user setpassword --newpassword="$PASSWORD" --must-change-at-next-login $DOMAIN_USER
echo "password change applied for next login"
pause
}

function user_list(){
echo ""
echo "::User List::"
echo "-------------"
samba-tool user list
pause
}

function create_group(){
echo ""
echo "::Create Group::"
echo "----------------"
GROUP_NAME=$(whiptail --title "Create Group" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
samba-tool group add $GROUP_NAME
pause
}

function delete_group(){
echo ""
echo "::Delete Group::"
echo "----------------"
GROUP_NAME=$(whiptail --title "Delete Group" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
samba-tool group delete $GROUP_NAME
pause
}

function add_member_group(){
echo ""
echo "::Add Member to Group::"
echo "-----------------------"
GROUP_NAME=$(whiptail --title "Group Name for Add Member" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
DOMAIN_USER=$(whiptail --title "Change Password at Next Logon" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool group addmembers $GROUP_NAME $DOMAIN_USER
pause
}

function remove_member_group(){
echo ""
echo "::Remove Member from Group::"
echo "----------------------------"
GROUP_NAME=$(whiptail --title "Group Name for Remove Member" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
DOMAIN_USER=$(whiptail --title "Change Password at Next Logon" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool group removemembers $GROUP_NAME $DOMAIN_USER
pause
}

function group_list(){
echo ""
echo "::Group List of Domain::"
echo "------------------------"
samba-tool group list
pause
}

function group_member_list(){
echo ""
echo "::List Members of Groups::"
echo "--------------------------"
GROUP_NAME=$(whiptail --title "List Members" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
samba-tool group listmembers $GROUP_NAME
pause
}

function create_ou() {
echo ""
echo "::Create a new OU::"
echo "--------------------------"
OU_NAME=$(whiptail --title "Create a new OU" --inputbox "Please enter the OU Name" 10 60  3>&1 1>&2 2>&3)
samba-tool ou create OU=$OU_NAME
pause
}

function delete_ou() {
echo ""
echo "::Delete OU::"
echo "--------------------------"
OU_NAME=$(whiptail --title "Delete OU" --inputbox "Please enter the OU Name" 10 60  3>&1 1>&2 2>&3)
samba-tool ou delete OU=$OU_NAME
pause
}

function move_user_ou() {
echo ""
echo "::Move User to OU::"
echo "--------------------------"
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
OU_NAME=$(whiptail --title "OU Name" --inputbox "Please enter the OU Name" 10 60  3>&1 1>&2 2>&3)
DCNAME1=$(samba-tool domain info $SERVER | grep "Domain" | cut -d ":" -f2 | cut -d "." -f1 | xargs)
DCNAME2=$(samba-tool domain info $SERVER | grep "Domain" | cut -d ":" -f2 | cut -d "." -f2 | xargs)
samba-tool user move $DOMAIN_USER "OU=$OU_NAME,DC=$DCNAME1,DC=$DCNAME2"
echo -e
pause
}

function ou_list() {
echo ""
echo "::OU List::"
echo "--------------------------"
samba-tool ou list
pause
}

function rename_ou() {
echo ""
echo "::Rename OU::"
echo "--------------------------"
OU_NAME=$(whiptail --title "OU Name" --inputbox "Please enter the OU Name" 10 60  3>&1 1>&2 2>&3)
NEW_OU_NAME=$(whiptail --title "OU Name" --inputbox "Please enter the New OU Name" 10 60  3>&1 1>&2 2>&3)
samba-tool ou rename OU="$OU_NAME" OU="$NEW_OU_NAME"
echo -e
echo "OU List grep $NEW_OU_NAME"
samba-tool ou list | grep "$NEW_OU_NAME"
pause
}

function add_dns_record(){
echo ""
echo "::Add to DNS record::"
echo "---------------------"
choice=$(whiptail --title "Add to DNS record" --radiolist "Choose:"     10 25 5 \
»···"A" "" on 3>&1 1>&2 2>&3)
case $choice in
A)
RECORD_NAME=$(whiptail --title "Record Name" --inputbox "Please enter the Record Name" 10 60  3>&1 1>&2 2>&3)
TARGET_IP=$(whiptail --title "IP of Record" --inputbox "Please enter the IP Address of Record" 10 60  3>&1 1>&2 2>&3)
samba-tool dns add $SERVER $ZONE $RECORD_NAME A $TARGET_IP -U administrator
;;
CNAME)
;;
*)
;;
esac
pause
}

function del_dns_record(){
echo ""
echo "::Delete a DNS record::"
echo "-----------------------"
RECORD_NAME=$(whiptail --title "Record Name" --inputbox "Please enter the Record Name" 10 60  3>&1 1>&2 2>&3)
RECORD_IP=$(whiptail --title "Record IP Address" --inputbox "Please enter the Record IP Adress" 10 60  3>&1 1>&2 2>&3)
samba-tool dns delete $SERVER $ZONE $RECORD_NAME A $RECORD_IP -U administrator
pause
}

function list_dns_records(){
echo ""
echo "::DNS Records::"
echo "---------------"
samba-tool dns query $SERVER $ZONE @ ALL -U administrator
pause
}

fsmo_role_transfer(){
echo ""
echo "::FSMO Role Transfer::"
echo "----------------------"
choice=$(whiptail --title "Select the FSMO Role to transfer" --radiolist "Choose:"    10 50 5 \
    "Schema Master Role" "" "Schema Master Role" \
    "Infrastructure Master Role" "" "Infrastructure Master Role" \
    "Rid Master Role" "" "Rid Master Role" \
    "Pdc Master Role" "" "Pdc Master Role" \
    "Domain Naming Master Role" "" "Domain Naming Master Role" 3>&1 1>&2 2>&3)
case $choice in
    "Schema Master Role")
        echo ""
        echo "Schema Master Role Owner"
        echo "------------------------"
        samba-tool fsmo show |grep "SchemaMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo transfer --role=schema
    ;;
    "Infrastructure Master Role")
        echo ""
        echo "Infrastructure Master Role Owner"
        echo "--------------------------------"
        samba-tool fsmo show |grep "InfrastructureMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo transfer --role=infrastructure
    ;;
    "Rid Master Role")
        echo ""
        echo "Rid Master Role Owner"
        echo "---------------------"
        samba-tool fsmo show |grep "RidAllocationMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo transfer --role=rid
    ;;
    "Pdc Master Role")
        echo ""
        echo "Pdc Master Role"
        echo "---------------"
        samba-tool fsmo show |grep "PdcEmulationMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo transfer --role=pdc
    ;;
    "Domain Naming Master Role")
        echo ""
        echo "Domain Naming Master Role"
        echo "-------------------------"
        samba-tool fsmo show |grep "DomainNamingMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo transfer --role=naming
    ;;
    *)
    ;;
esac
pause
}

function fsmo_role_seize(){
echo ""
echo "::FSMO Role Transfer::"
echo "----------------------"
choice=$(whiptail --title "Select the FSMO Role to transfer" --radiolist "Choose:"    10 50 5 \
    "Schema Master Role" "" "Schema Master Role" \
    "Infrastructure Master Role" "" "Infrastructure Master Role" \
    "Rid Master Role" "" "Rid Master Role" \
    "Pdc Master Role" "" "Pdc Master Role" \
    "Domain Naming Master Role" "" "Domain Naming Master Role" 3>&1 1>&2 2>&3)
case $choice in
    "Schema Master Role")
        echo ""
        echo "Schema Master Role Owner"
        echo "------------------------"
        samba-tool fsmo show |grep "SchemaMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo seize --role=schema
    ;;
    "Infrastructure Master Role")
        echo ""
        echo "Infrastructure Master Role Owner"
        echo "--------------------------------"
        samba-tool fsmo show |grep "InfrastructureMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo seize --role=infrastructure
    ;;
    "Rid Master Role")
        echo ""
        echo "Rid Master Role Owner"
        echo "---------------------"
        samba-tool fsmo show |grep "RidAllocationMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo seize --role=rid
    ;;
    "Pdc Master Role")
        echo ""
        echo "Pdc Master Role"
        echo "---------------"
        samba-tool fsmo show |grep "PdcEmulationMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo seize --role=pdc
    ;;
    "Domain Naming Master Role")
        echo ""
        echo "Domain Naming Master Role"
        echo "-------------------------"
        samba-tool fsmo show |grep "DomainNamingMasterRole" |cut -d "," -f2
        echo ""
        samba-tool fsmo seize --role=naming
    ;;
    *)
    ;;
esac
pause
}

function dns_role_seize(){
echo ""
echo "::DNS Role Seize::"
echo "----------------------"
choice=$(whiptail --title "Select the DNS Role" --radiolist "Choose:"    10 50 5 \
    "Domain DNS Zone Master Role" "" "Domain DNS Zone Master Role" \
    "Forest DNS Zone Master Role" "" "Forest DNS Zone Master Role" 3>&1 1>&2 2>&3)
case $choice in
    "Domain DNS Zone Master Role")
        echo ""
        echo "Domain DNS Zone Master Role Owner"
        echo "---------------------------------"
        samba-tool fsmo show |grep "DomainDnsZonesMasterRole" |cut -d "," -f2
        echo ""
        echo "cf. DNS Management Documention"
        echo ""
    ;;
    "Forest DNS Zone Master Role")
        echo ""
        echo "Forest DNS Zone Master Role Owner"
        echo "---------------------------------"
        samba-tool fsmo show |grep "ForestDnsZonesMasterRole" |cut -d "," -f2
        echo ""
        echo "cf. DNS Management Documention"
        echo ""
    ;;
    *)
    ;;
esac
pause
}

function show_fsmo_roles(){
echo ""
	echo "::FSMO Roles of DC's::"
	echo "----------------------"
	samba-tool fsmo show
	pause
}

function show_dc_host(){
echo ""
echo "::DC Host List::"
echo "---------------"
samba-tool ou listobjects OU="Domain Controllers" |cut -d "," -f1
pause
}

function demote_dc_host(){
echo ""
echo "::Demote DC Host::"
echo "------------------"
choice=$(whiptail --title "Demote DC" --radiolist "Choose:"     10 25 5 \
        "This Host" "" "This Host" \
	"Remote Host" "" "Remote Host" 3>&1 1>&2 2>&3)
case $choice in
    "This Host")
    samba-tool domain demote -U Administrator
    ;;
    "Remote Host")
    DCNAME=$(whiptail --title "DC Name" --inputbox "Please enter the DC Name for demote" 10 60  3>&1 1>&2 2>&3)
    samba-tool domain demote --remove-other-dead-server=$DCNAME
    ;;
    *)
    ;;
esac
pause
}

function show_pass_settings(){
echo ""
echo "::Show Password Settings::"
echo "--------------------------"
samba-tool domain passwordsettings show
pause
}

function set_pass_length(){
echo ""
echo "::Set Password Settings::"
echo "-------------------------"
MIN_PASS_LENGTH=$(whiptail --title "Minimum Password Length" --inputbox "Please enter the Minimum Password Length Value" 10 60  3>&1 1>&2 2>&3)
samba-tool domain passwordsettings set --min-pwd-length=$MIN_PASS_LENGTH
pause
}

function set_pass_history_length(){
echo ""
echo "::Set Password History Length::"
echo "-------------------------------"
PASS_HIST_LENGTH=$(whiptail --title "Password History Length" --inputbox "Please enter the Password History Length Value" 10 60  3>&1 1>&2 2>&3)
samba-tool domain passwordsettings set --history-length=$PASS_HIST_LENGTH
pause
}

function set_pass_age(){
echo ""
echo "::Set Password Age::"
echo "--------------------"
choice=$(whiptail --title "Set Password Age" --radiolist "Choose:"     10 25 5 \
	"Minimum" "" on \
	"Maximum" "" off 3>&1 1>&2 2>&3)
case $choice in
Minimum)                      
MIN_PASS_AGE=$(whiptail --title "Set Minimum Password Age" --inputbox "Please enter the Minimum Password Age Value" 10 60  3>&1 1>&2 2>&3)
samba-tool domain passwordsettings set --min-pwd-age=$MIN_PASS_AGE
;;    
Maximum)
MAX_PASS_AGE=$(whiptail --title "Set Maximum Password Age" --inputbox "Please enter the Maximum Password Age Value" 10 60  3>&1 1>&2 2>&3)
samba-tool domain passwordsettings set --max-pwd-age=$MAX_PASS_AGE
;;    
*)    
;;    
esac                    
pause 
}

function pass_complexity(){
echo ""
	echo "::Password Complexity::"
	echo "-----------------------"
	choice=$(whiptail --title "Password Complexity" --radiolist "Choose:"     10 25 5 \
		"activate" "" activate \
		"deactivate" "" deactivate 3>&1 1>&2 2>&3)
			case $choice in
				activate)
					samba-tool domain passwordsettings set --complexity=on
					;;
				deactivate)
					samba-tool domain passwordsettings set --complexity=off
					;;
				*)
					;;
			esac
			pause
}

function db_check(){
echo ""
	echo "::DB Check::" 
	echo "------------"
	samba-tool dbcheck
	pause
}


function show_processes(){
echo ""
	echo "::Show Processes::"
	echo "------------------"
	samba-tool processes
	pause
}

function info_of_domain(){
echo ""
	echo "::Domain Info::"
	echo "---------------"
	samba-tool domain info $SERVER
	echo "---------------"
	samba-tool domain level show
	pause
}

function replication_status(){
	samba-tool drs showrepl
	pause
}

function listening_ports(){
	#netstat -tulanp| egrep "ntp|bind|named|samba|?mbd"
	nmap 127.0.0.1
	pause
}

function dns_status(){
	netstat -tulpn | grep ":53"
	pause
}

function about_of(){
    echo ""
    echo "---------------------------------------------------------------------------------------------------"
    echo "::..About of SambaAD-tui..:: - v2 -"
    echo "---------------------------------------------------------------------------------------------------"
    echo "SambAD-tui provides a Text User Interface for Samba Active Directory"
    echo "This application in used on the Active Directory Server e.g.DC1"
    echo "---------------------------------------------------------------------------------------------------"
    echo "Current Features;
    - User Management
    - Group Management
    - DNS Management
    - FSMO and DNS Role Management
    - DC Management
    - Settings(password length,complexity,age)
    - Maintenance and Troubleshooting menüs"
    echo ""
	echo "Planning;
    - Managing other DNS record
	- Managing more than one ZONE
	- Managing OU
	- Managing Group Policy"
	echo ""
	echo "---------------------------------------------------------------------------------------------------"
	echo "Changelog;
    v2   : FSMO roles management Menu, DC Management Menu
    v1.1 : listening ports, DNS status, DNS Query, Replication Status menus added for domain environment controls"
	pause
}

function query_dns_all(){
	REALM=$(cat /etc/samba/smb.conf |grep realm |cut -d "=" -f2 |cut -d " " -f2)
	samba-tool dns query $REALM $REALM @ ALL -U Administrator
	pause
}

function logviewer(){
        LOGFILE=$(cat /etc/samba/smb.conf | grep "log file" | cut -d "=" -f2 | xargs)
        cat "$LOGFILE"
        echo ""
        echo "----------------------------------------------------------------------- log file showed from sambadtui -----------------------------------------------------------------------"
        echo ""
        pause
}

function read_input(){
local c
read -p "${BOLD}${WHITE}You can choose from the menu numbers${RESET} " c
case $c in
0)about_of ;;
1)create_user ;;
2)delete_user ;;
3)disable-enable_user;;
4)set_expiration ;;
5)change_password ;;
6)change_pass_nextlogon ;;
7)user_list ;;
11)create_group ;;
12)delete_group ;;
13)add_member_group ;;
14)remove_member_group ;;
15)group_list ;;
16)group_member_list ;;
21)create_ou ;;
22)delete_ou ;;
23)move_user_ou ;;
24)ou_list ;;
25)rename_ou ;;
31)add_dns_record ;;
32)del_dns_record ;;
33)list_dns_records ;;
51)fsmo_role_transfer ;;
52)fsmo_role_seize ;;
53)dns_role_seize ;;
55)show_dc_host ;;
56)demote_dc_host ;;
71)show_pass_settings ;;
72)set_pass_length ;;
73)set_pass_history_length ;;
74)set_pass_age ;;
75)pass_complexity ;;
81)db_check ;;
82)show_fsmo_roles ;;
83)show_processes ;;
84)info_of_domain ;;
85)replication_status ;;
86)listening_ports ;;
87)dns_status ;;
88)query_dns_all ;;
90)logviewer ;;
99)exit 0 ;;
*)
echo "Please select from the menu numbers"
pause
esac
}

# CTRL+C, CTRL+Z
trap '' SIGINT SIGQUIT SIGTSTP

while true
do
clear
show_menu
read_input
done
