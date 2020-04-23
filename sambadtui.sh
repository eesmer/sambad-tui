#!/bin/bash
#buildnumber:20190307-14:30

if ! [ -x "$(command -v whiptail)" ]; then
apt -y install whiptail
fi

SERVER=$(ip r |grep link |grep src |cut -d'/' -f2 |cut -d'c' -f3 |cut -d' ' -f2)
ZONE=$(samba-tool domain info $SERVER |grep Domain |cut -d':' -f2 |cut -d' ' -f2)

samba-tool domain passwordsettings set --min-pwd-age=0 # for Password_Change_Next_Logon to work after create user

if [ ! -e "about" ]; then
cat > about <<EOF
#-------------------------------------------------------------------------------------------------------------------------------------------#
SambAD-tui provides a Text User Interface for Samba Active Directory management.
This application in used on the Active Directory Server e.g.DC1
#-------------------------------------------------------------------------------------------------------------------------------------------#
The following lines writed the current versions features and the items planned for future releases.
# V1 #
User Management, Group Management, DNS Management, Settings(password length,complexity,age), Maintenance(DB check, show fsmo roles,processes)
----------------------------------------------------------------------------------------------------------------------------------------------
Future Releases;
- to be able to manage other types of DNS records
- to be able to manage more than one Zone
- to be able to do OU management
- to be able to manage FSMO roles
- to be able to work with more than one DC
- to be able to manage Group Policy
- Web interface maybe:)
EOF
fi

function pause(){
local message="$@"
[ -z $message ] && message="Press Enter to continue"
read -p "$message" readEnterKey
}

function show_menu(){
date
echo "   |----------------------------------------------------------------------------|"
echo "   |SambaAd-tui V1                                                              |"
echo "   |----------------------------------------------------------------------------|"
echo "   | User Management                 | Group Management  | DNS Management       |"
echo "   |---------------------------------|-------------------|----------------------|"
echo "   | 1.Create User                   | 11.Create Group   | 21.Add DNS Record    |"
echo "   | 2.Delete User                   | 12.Delete Group   | 22.Delete DNS Record |"
echo "   | 3.Disable/Enable User           | 13.Add Member     | 23.DNS Records List  |"
echo "   | 4.Set Expiration                | 14.Remove Member                         |"
echo "   | 5.Change Password               | 15.Group List                            |"
echo "   | 6.Change Password at Next Logon | 16 Member List                           |"
echo "   | 7.User List                     |                                          |"
echo "   |----------------------------------------------------------------------------|"
echo "   |                        Settings & Maintenance                              |"
echo "   |---------------------------------|------------------------------------------|"
echo "   | 31.Show Password Settings       | 41.AD Database Check                     |"
echo "   | 32.Set Password Length          | 42.Show to FSMO Roles                    |"
echo "   | 33.Set Password History Length  | 43.Show to Processes                     |"
echo "   | 34.Set Password Age             | 44.Domain Info                           |"
echo "   | 35.Password Complexity                                                     |"
echo "   |----------------------------------------------------------------------------|"
echo "   | 99.Exit | 0.About                                                          |"
echo "   |----------------------------------------------------------------------------|"
}

function create_user(){
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
echo "::Delete User::"
echo "---------------"
DOMAIN_USER=$(whiptail --title "User UserName" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool user delete $DOMAIN_USER
pause
}

function disable-enable_user(){
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
echo "::Change Password::"
echo "-------------------"
DOMAIN_USER=$(whiptail --title "Change Password" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --title "Set Password" --passwordbox "Please enter the password you want to assign" 10 60  3>&1 1>&2 2>&3)
samba-tool user setpassword --newpassword="$PASSWORD" $DOMAIN_USER
pause
}

function change_pass_nextlogon(){
echo "::Change Password at Next Logon::"
echo "---------------------------------"
DOMAIN_USER=$(whiptail --title "Change Password at Next Logon" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --title "Set Password" --passwordbox "Please enter the Temporary Password" 10 60  3>&1 1>&2 2>&3)
samba-tool user setpassword --newpassword="$PASSWORD" --must-change-at-next-login $DOMAIN_USER
echo "password change applied for next login"
pause
}

function user_list(){
echo "::User List::"
echo "-------------"
samba-tool user list
pause
}

function create_group(){
echo "::Create Group::"
echo "----------------"
GROUP_NAME=$(whiptail --title "Create Group" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
samba-tool group add $GROUP_NAME
pause
}

function delete_group(){
echo "::Delete Group::"
echo "----------------"
GROUP_NAME=$(whiptail --title "Delete Group" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
samba-tool group delete $GROUP_NAME
pause
}

function add_member_group(){
echo "::Add Member to Group::"
echo "-----------------------"
GROUP_NAME=$(whiptail --title "Group Name for Add Member" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
DOMAIN_USER=$(whiptail --title "Change Password at Next Logon" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool group addmembers $GROUP_NAME $DOMAIN_USER
pause
}

function remove_member_group(){
echo "::Remove Member from Group::"
echo "----------------------------"
GROUP_NAME=$(whiptail --title "Group Name for Remove Member" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
DOMAIN_USER=$(whiptail --title "Change Password at Next Logon" --inputbox "Please enter the Username" 10 60  3>&1 1>&2 2>&3)
samba-tool group removemembers $GROUP_NAME $DOMAIN_USER
pause
}

function group_list(){
echo "::Group List of Domain::"
echo "------------------------"
samba-tool group list
pause
}

function group_member_list(){
echo "::List Members of Groups::"
echo "--------------------------"
GROUP_NAME=$(whiptail --title "List Members" --inputbox "Please enter the Group Name" 10 60  3>&1 1>&2 2>&3)
samba-tool group listmembers $GROUP_NAME
pause
}

function add_dns_record(){
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
echo "::Delete a DNS record::"
echo "-----------------------"
RECORD_NAME=$(whiptail --title "Record Name" --inputbox "Please enter the Record Name" 10 60  3>&1 1>&2 2>&3)
RECORD_IP=$(whiptail --title "Record IP Address" --inputbox "Please enter the Record IP Adress" 10 60  3>&1 1>&2 2>&3)
samba-tool dns delete $SERVER $ZONE $RECORD_NAME A $RECORD_IP -U administrator
pause
}

function list_dns_records(){
echo "::DNS Records::"
echo "---------------"
samba-tool dns query $SERVER $ZONE @ ALL -U administrator
pause
}

function show_pass_settings(){
echo "::Show Password Settings::"
samba-tool domain passwordsettings show
pause
}

function set_pass_length(){
echo "::Set Password Settings::"
MIN_PASS_LENGTH=$(whiptail --title "Minimum Password Length" --inputbox "Please enter the Minimum Password Length Value" 10 60  3>&1 1>&2 2>&3)
samba-tool domain passwordsettings set --min-pwd-length=$MIN_PASS_LENGTH
pause
}

function set_pass_history_length(){
echo "::Set Password History Length::"
PASS_HIST_LENGTH=$(whiptail --title "Password History Length" --inputbox "Please enter the Password History Length Value" 10 60  3>&1 1>&2 2>&3)
samba-tool domain passwordsettings set --history-length=$PASS_HIST_LENGTH
pause
}

function set_pass_age(){
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
echo "::DB Check::" 
echo "------------"
samba-tool dbcheck
pause
}

function show_fsmo_roles(){
echo "::FSMO Roles of DC's::"
echo "----------------------"
samba-tool fsmo show
pause
}

function show_processes(){
echo "::Show Processes::"
echo "------------------"
samba-tool processes
pause
}

function domain_info(){
echo "::Domain Info::"
echo "---------------"
samba-tool domain info $SERVER
samba-tool domain level show
pause
}

function about_of(){
echo ""
echo "::..About of SambAd-tui..::"
cat about
pause
}

function read_input(){
local c
read -p "You can choose from the menu numbers " c
case $c in
0)	about_of ;;
1)	create_user ;;
2)	delete_user ;;
3)	disable-enable_user;;
4)	set_expiration ;;
5)	change_password ;;
6)	change_pass_nextlogon ;;
7)	user_list ;;
11)	create_group ;;
12)	delete_group ;;
13)	add_member_group ;;
14)	remove_member_group ;;
15)	group_list ;;
16)	group_member_list ;;
21)	add_dns_record ;;
22)	del_dns_record ;;
23)	list_dns_records ;;
31)	show_pass_settings ;;
32)	set_pass_length ;;
33)	set_pass_history_length ;;
34)	set_pass_age ;;
35)	pass_complexity ;;
41)	db_check ;;
42)	show_fsmo_roles ;;
43)	show_processes ;;
44)	domain_info ;;
99)	exit 0 ;;
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
