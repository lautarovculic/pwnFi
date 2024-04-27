#!/bin/bash

# v0.2
# https://lautarovculic.com

# Colors #########################
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"
##################################

# CTRL-C EXIT #####################################
trap ctrl_c INT
function ctrl_c(){
	echo -e "\n${redColor}Exiting...${endColor}\n"
	tput cnorm; sudo airmon-ng stop ${networkCard}mon > /dev/null 2>&1; sudo ifconfig ${networkCard} up
	exit 0
}
###################################################

# helpPanel ########################
function helpPanel(){
	echo -e "\n${yellowColor}>>${endColor} ${grayColor} Usage: ${endColor}${redColor}sudo${endColor}${grayColor} ./pwnFi.sh${endColor}"
	echo -e "\t${yellowColor}-a${endColor}${grayColor} Attack Mode${endColor}"
	echo -e "\t\t${yellowColor}Handshake${endColor}"
	echo -e "\t\t${yellowColor}PKMID${endColor}"
	echo -e "\t${yellowColor}-n${endColor}${grayColor} Network Card${endColor}"
	echo -e "\t${yellowColor}-h${endColor}${grayColor} Show this message${endColor}"
	echo -e "\n${yellowColor}Example:${endColor} ${grayColor}sudo ./pwnFi.sh -a PKMID -n wlan0${endColor}"
	echo -e "\n${grayColor}Net cards available:${endColor}\n${yellowColor}$(ip link show | awk '$2 !~ /^[0-9a-fA-F:]{17}$/ {print $2}' | tr -d ':')${endColor}\n"
	exit 0
}
####################################

# startAttack
function startAttack(){
	clear
	echo -e "${greenColor}[*]${endColor} ${grayColor}Setting monitor mode...${endColor}"
	# Up the net card
	sudo ifconfig ${networkCard} up
	# Monitor mode
	sudo airmon-ng start $networkCard > /dev/null 2>&1
	# Down the net card and change the MAC Address
	sudo ifconfig ${networkCard}mon down && macchanger -a ${networkCard}mon > /dev/null 2>&1
	# Up the net card
	sudo ifconfig ${networkCard}mon up
	# Kill proccess
	sudo killall dhclient wpa_supplicant 2>/dev/null

	# Show new MAC Address
	echo -e "\n${greenColor}[*]${endColor} ${grayColor}New MAC Adrress:${endColor} ${redColor}$(sudo macchanger -s ${networkCard}mon | grep -i current | xargs | cut -d ' ' -f '3-100')${endColor}"



	exit 0
}

# dependencies
function dependencies(){
	sudo airmon-ng stop ${networkCard}mon > /dev/null 2>&1
	tput civis
	clear; dependencies=(aircrack-ng macchanger)

	echo -e "${yellowColor}>> Checking dependencies...${endColor}"
	sleep 2

	for program in "${dependencies[@]}"; do
		echo -ne "\n\t${yellowColor}>>${endColor} ${grayColor}Tool ${endColor}${redColor}$program${endColor}${grayColor}...${endColor}"

		test -f /usr/bin/$program

		if [ "$(echo $?)" == "0" ]; then
			echo -e "${greenColor} (OK)${endColor}\n"
		else
			echo -e "${redColor} (X)${endColor}\n"
			if [[ "$(lsb_release -si)" == "Ubuntu" || "$(lsb_release -si)" == "Debian" ]]; then
				export DEBIAN_FRONTEND=noninteractive
				echo -e "${yellowColor}Installing $program${endColor}"
				sudo apt-get install aircrack-ng macchanger -y
			elif [ "$(lsb_release -si)" == "Arch" ]; then
				echo -e "${yellowColor}Installing $program${endColor}"
				sudo pacman -Syyu aircrack-ng macchanger
			else
				echo -e "${yellowColor}Installing $program${endColor}"
				sudo apt-get install aircrack-ng macchanger -y
			fi; tput cnorm; sleep 1; exit 0
		fi; tput cnorm; sleep 1;
	done
}

#
# Main
#

if [ "$(id -u)" == "0" ]; then
	# Options
	declare -i paramCounter=0;  while getopts ":a:n:h:" arg; do
		case $arg in
			a) attackMode=$OPTARG; let paramCounter+=1 ;;
			n) networkCard=$OPTARG; let paramCounter+=1 ;;
			h) helpPanel ;;
		esac
	done

	if [ $paramCounter -ne 2 ]; then
		helpPanel
	else
		dependencies
		startAttack
		tput cnorm
	fi

else
	echo -e "\n${redColor}>> You must be root <<${endColor}\n"
fi
