#!bin/bash


# Createt the Array containing IP addresses
ips=("192.168.40.342" "192.168.40.01" "192.168.40.003" "192.168.40.600" "192.168.40.020" "192.168.40.230" "192.168.40.50" "192.168.40.68")

# Ask user to enter a computer number
read -p "Please enter the new employees' assigned computer number:" number

if [[ -z "$number" ]]; then 
   echo "Seriously...enter it."
   exit 1
fi

echo "The computer's ip number is: ${ips[$number-1]}"