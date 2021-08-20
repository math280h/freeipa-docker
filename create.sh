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
echo "Docker freeipa-container Setup"
echo "Brought to you by math280h - ${green}https://github.com/math280h"
printf "\n"

# Get config for starting Docker Container
echo "${blue}Setup Configuration:${reset}"

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

# Try to create new directory for freeipa
if [ -d "/var/lib/$HOSTNAME" ]; then
  # Control will enter here if directory $HOSTNAME exists.
  echo "${red}Error: directory with that name already exists (path: /var/lib/$HOSTNAME)!" 1>&2
  exit 64
else
  mkdir "/var/lib/$HOSTNAME"
  if [ -d "/var/lib/$HOSTNAME" ]; then
    # Control that folder was created
    echo "${green}Success: Directory was successfully created (path: /var/lib/$HOSTNAME)"
    chown "$USER":"$USER" "/var/lib/$HOSTNAME"
  else
    echo "${red}Error: an unknown error occurred while creating directory" 1>&2
    exit 64
  fi
fi

# Checking if Docker Container is running
RESULT=$(docker container ls -a --filter "name=$NAME")
if [[ $RESULT == *$NAME* ]]; then
  # Docker Container was found - Shutting down script
  echo "${red}Docker Container was already found - Please choose another name" 1>&2
  rm -r "/var/lib/$HOSTNAME"
  exit 64
else
  # Trying to pull Docker Container
  docker pull freeipa/freeipa-server:fedora-34

  # Trying to start Docker Container
  docker run --name "$NAME" -ti \
         -h "$HOSTNAME" --read-only \
         -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
         --tmpfs /run \
         --tmpfs /tmp \
         -v "/var/lib/$HOSTNAME:/data:Z" \
         freeipa/freeipa-server:fedora-34

  # Checking if Docker Container is running
  RESULT=$(docker container ls -a --filter "name=$NAME")
  if [[ $RESULT == *$NAME* ]]; then
    # Docker Container was found - Shutting down script
    echo "${green}Docker Container was found Successfully!"
    echo "Thanks for using the script - The script will now close and you can continue setup!"
  else
    # Docker could not run, cleanup after script
    echo "${red}Error: Could not find Docker Container - Initiating cleanup and closing script" 1>&2
    rm -r "/var/lib/$HOSTNAME"
    exit 64
  fi
fi
