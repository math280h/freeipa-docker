#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
reset=$(tput sgr0)

# Checking if user is sudo (Required for running setup)
if [ "$(whoami)" != root ]; then
    echo "${red}Error: Please run this script as root or using sudo"
    exit
fi

# Show Introduction
echo "Docker freeipa-container Deletion"
echo "Brought to you by math280h - ${green}https://github.com/math280h"
printf "\n"

# Get config for starting Docker Container
echo "${blue}Deletion Configuration:${reset}"

# Get Docker Container Name
echo "Enter Docker Container Name:"
read -r NAME

# Get freeipa Hostname
echo "Enter hostname (e.g: ipa.domain.local):"
read -r HOSTNAME

if [[ -z $NAME || -z $HOSTNAME ]]; then
  echo "${red}Configuration must NOT be empty" 1>&2
  exit 64
fi

# Checking if Docker Container is running
RESULT=$(docker container ls -a --filter "name=$NAME")
if [[ $RESULT == *$NAME* ]]; then
    # Docker Container was found - Starting
    echo "${green}Docker Container was found - Starting process" 1>&2

    # Trying to kill docker container
    docker kill "$(docker container ls -a -q --filter "name=$NAME"*)"
    docker rm "$(docker container ls -a -q --filter "name=$NAME"*)"
else
    echo "${red}Docker Container was not found - Please enter the correct name and hostname" 1>&2
    exit 64
fi

# Allowing Docker to kill container
echo "Waiting 5 seconds before checking if container is dead"
sleep 5

# Checking if Docker Container is running
RESULT=$(docker container ls -a --filter "name=$NAME")
if [[ $RESULT == *$NAME* ]]; then
    # Docker Container was found - Shutting down script
    echo "${red}Docker Container was found - Something went wrong, please kill the container manually and run the script again" 1>&2
    exit 64
else
    # Docker could not run, cleanup after script
    echo "${green}Could not find Docker Container - Initiating cleanup"
    # Try to delete directory for freeipa
    if [ -d "/var/lib/$HOSTNAME" ]; then
        # Control will enter here if directory $HOSTNAME exists.
        echo "${green}Folder found, starting deletion (path: /var/lib/$HOSTNAME)!"
        rm -r "/var/lib/$HOSTNAME"
        if [ -d "/var/lib/$HOSTNAME" ]; then
            # Control that folder was created
            echo "${green}Cleanup Finished"
            echo "Thanks for using the script - The script will now close and you can continue setup!"
        else
            echo "${red}Error: an unknown error occurred while deleting directory" 1>&2
            exit 64
        fi
    else
        echo "${red}Error: directory with that name does not exist (path: /var/lib/$HOSTNAME)!" 1>&2
        exit 64
    fi
fi
