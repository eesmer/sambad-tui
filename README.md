
***I combined this work with the DebianDC installation aiming to provide a management GUI for any debian installation.<br>
If you are interested in this topic; you can have a look at[DebianDC](https://github.com/eesmer/DebianDC)

# Samba Active Directory -Text User Interface
Sambadtui, provides a Text User Interface for Samba Active Directory.
<br> This application in used on the Active Directory Server.

Sambadtui, does not install Active Directory.
You can run on the existing installation. (e.g.DC1)

## Features
- User Management
- Group Management
- DNS Management
- Settings (password length,complexity,age)
- Maintenance

## Requirements
It works in Debian environment. Desktop environment is not required.

## Installation and Usage
```sh
$ wget https://raw.githubusercontent.com/eesmer/sambad-tui/master/sambadtui.sh
$ bash sambadtui.sh
```
Use sambadtui with root user
