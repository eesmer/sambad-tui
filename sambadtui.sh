#!/bin/bash
#buildnumber:20221209-09:45

if ! [ -x "$(command -v whiptail)" ]; then
apt -y install whiptail
fi
if ! [ -x "$(command -v netstat)" ]; then
apt -y install net-tools
fi

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
echo "   |--------------------------------------------------------------------------------------|"
echo "   | SambaAD-tui v1.1                                                                     |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | User Management           | Group Management | OU Management | DNS Management        |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | 1.Create User             | 11.Create Group  | 21.Create OU  | 31.Add DNS Record     |"
echo "   | 2.Delete User             | 12.Delete Group  | 22.Delete OU  | 32.Delete DNS Record  |"
echo "   | 3.Disable/Enable User     | 13.Add Member    | 23 OU List    | 33.DNS Records List   |"
echo "   | 4.Set Expiration          | 14.Remove Member |                                       |"
echo "   | 5.Change Password         | 15.Group List    |                                       |"
echo "   | 6.Change Pass.Next Logon  | 16 Member List   |                                       |"
echo "   | 7.User List               |                  |                                       |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | FSMO Management           | DC Management    |                                       |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | 51.Role Transfer          | 55.Show DC Hosts |                                       |"
echo "   | 82.Show Roles             | 56.Demote DC     |                                       |"
echo "   |                           | 57.Add ADC       |                                       |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | Domain Settings           | Troubleshooting & Maintenance                            |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | 71.Show Password Settings | 81.Database Check   86.Listening Ports                   |"
echo "   | 72.Set Password Length    | 82.Show FSMO Roles  87.DNS Status                        |"
echo "   | 73.Set Password History   | 83.Show Processes   88.Query DNS Records                 |"
echo "   | 74.Set Password Age       | 84.Domain Info                                           |"
echo "   | 75.Password Complexity    | 85.Repl.Status                                           |"
echo "   |--------------------------------------------------------------------------------------|"
echo "   | 99.Exit | 0.About                                                                    |"
echo "   |--------------------------------------------------------------------------------------|"
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
	"SetExpiration" "" on \
	"NoExpiry" "" off 3>&1 1>&2 2>&3)
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

function add_dns_record(){
echo ""
echo "::Add to DNS record::"
echo "---------------------"
choice=$(whiptail --title "Add to DNS record" --radiolist "Choose:"     10 25 5 \
	"A" "" on 3>&1 1>&2 2>&3)
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

function show_dc_host(){
echo ""
echo "::DC Host List::"
echo "---------------"
samba-tool ou listobjects OU="Domain Controllers" |cut -d "," -f1
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

function show_fsmo_roles(){
echo ""
	echo "::FSMO Roles of DC's::"
	echo "----------------------"
	samba-tool fsmo show
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
	netstat -tulanp| egrep "ntp|bind|named|samba|?mbd"
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
	echo "The following lines writed the current versions features and the items planned for future releases."
	echo ""
	echo "Current Features;
	- User Management
	- Group Management
	- DNS Management
	- Settings(password length,complexity,age)
	- Maintenance and Troubleshooting menüs"
	echo ""
	echo "Planning;
	- Managing other DNS record
	- Managing more than one ZONE
	- Managing OU
	- Managing FSMO Roles
	- Working with more than on DC
	- Managing Group Policy"
	echo ""
	echo "---------------------------------------------------------------------------------------------------"
	echo "Changelog;
	listening ports, DNS status, DNS Query, Replication Status menus added for domain environment controls"
	pause
}

function query_dns_all(){
	REALM=$(cat /etc/samba/smb.conf |grep realm |cut -d "=" -f2 |cut -d " " -f2)
	samba-tool dns query $REALM $REALM @ ALL -U Administrator
	pause
}

function read_input(){
local c
read -p "You can choose from the menu numbers " c
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
31)add_dns_record ;;
32)del_dns_record ;;
33)list_dns_records ;;
55)show_dc_host ;;
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
