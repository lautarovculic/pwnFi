# pwnFi.sh

## Description
This Bash script is designed for performing Wi-Fi penetration testing attacks, specifically targeting WPA/WPA2 networks using PSK (Pre-Shared Key). It supports two attack modes: Handshake and PKMID attack. The script automates various steps including setting up monitor mode, capturing handshakes or PKMID messages, deauthentication, and cracking passwords using Aircrack-ng or John the Ripper.

## Features
- Supports both Handshake and PKMID attack modes.
- Automatically sets up monitor mode on the specified network interface.
- Provides a user-friendly interface with options to select attack mode, network card, and view available network interfaces.
- Checks for and installs missing dependencies automatically.
- Utilizes color-coded output for better readability.

## Usage
```bash
sudo ./pwnFi.sh -a <Attack Mode> -n <Network Card>
```

### Options
- `-a <Attack Mode>`: Specify the attack mode (Handshake or PKMID).
- `-n <Network Card>`: Specify the network interface card to use for the attack.

## Prerequisites
- Linux operating system (Tested on Kali Linux and Arch Linux).
- Required tools: Aircrack-ng, Macchanger, Xterm, hcxdumptool, hcxpcaptool, John the Ripper, Aireplay-ng, Airmon-ng, Airodump-ng.

## Installation
No installation required. Simply download the script and make it executable using the following command:
```bash
chmod +x pwnFi.sh
```

## Example
```bash
sudo ./pwnFi.sh -a Handshake -n wlan0
```

