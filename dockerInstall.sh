#!/bin/sh

# Docker CE for Linux installation script
#
# See https://docs.docker.com/engine/install/ for the installation steps.
#

# Enter Version
input=${1}

echo "\e[31mInstall Docker Engine\e[0m"

# Global Value
DOCKER_VERSION=NULL
VERSION_STRING=NULL


# Verify Docker Version To be Install
enter_version() {
  echo "Input Version : $input"

  if [ -z "$input" ]; then
    DOCKER_VERSION="20.10.14"
  else
    DOCKER_VERSION=$input
  fi

  echo
  echo "Docker Version :" "\e[31m $DOCKER_VERSION \e[0m"
}


# Add Google DNS
add_google_dns() {
  echo
  echo
  echo "\e[36m1. Add Google DNS \e[0m"
  echo "1) Check Google DNS"
  tmp=$(grep -rin "8.8.8.8" /etc/resolv.conf)
  
  if [ -z "$tmp" ]; then
    echo "\e[33m- Add Google DNS. \e[0m"
    echo "\nnameserver 8.8.8.8" >> /etc/resolv.conf
  else
    echo "\e[33m- Already Set Google DNS. \e[0m"
  fi
}


# Setup Repository
setup_repository() {
  echo
  echo 
  echo "\e[36m2. Set up the repository. \e[0m"
  echo "1) Update the apt package index and install packages to allow apt to use a repository over HTTPS:"

  echo "\e[33m- Update Package list. \e[0m"
  apt-get update

  echo "\e[33m- Install Package. \e[0m"
  apt-get -y install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release

  echo "\e[33m- Remove Unnecessary Packages. \e[0m"
  apt -y autoremove


  echo
  echo "2) Add Docker’s official GPG key"
  tmp=$(find /etc/apt/keyrings/ -name docker-archive-keyring.gpg)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Official GPG key. \e[0m"
		mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  else
    echo "\e[33m- Already exists. \e[0m"
  fi


  echo
  echo "3) Use the following command to set up the stable repository"
  tmp=$(find /etc/apt/keyrings/ -name docker-archive-keyring.gpg)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Set up the Stable Repository. \e[0m"
		echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  else
    echo "\e[33m- Already exists. \e[0m"
  fi

}


# Install Docker Engine
install_docker_engine() {
  echo 
  echo
  echo "\e[36m3. Install Docker Engine \e[0m"
  apt-get update
  #apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
  echo "1) Check the apt package index" 
  apt-cache madison docker-ce
  # 20220414
  #  docker-ce | 5:20.10.14~3-0~ubuntu-focal | https://download.docker.com/linux/ubuntu focal/stable amd64 Packages
  # 20220602
  #  docker-ce | 5:20.10.14~3-0~ubuntu-jammy | https://download.docker.com/linux/ubuntu jammy/stable amd64 Packages
  VERSION_STRING=$(apt-cache madison docker-ce | grep $DOCKER_VERSION | awk '{print $3}')

  echo
  if [ -z "$VERSION_STRING" ]; then
    echo "\e[31m- No longer supports that version. \e[0m"
		apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
  else
    echo "2) Install a specific version"
    apt-get -y install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-compose-plugin
  fi
}


# Verify the Docker Version Installed
check_version() {
  echo
  echo 
  echo "\e[36m4. Verify the Docker Version Installed \e[0m"
  tmp=$(docker version)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Not properly installed. \e[0m"
  else
    docker version
  fi

  echo
  echo "\e[33m- Docker Daemon Status. \e[0m"
  systemctl is-active --quiet docker && echo "\e[35mDocker is running.\e[0m" || echo "\e[35mDocker is NOT running.\e[0m"

  echo
  echo "\e[31m Complete \e[0m"
  echo
}


# Main Function
do_main () {
  # Verify Docker Version To be Install
  enter_version

  # Add Google DNS
  add_google_dns

  # Setup Repository
  setup_repository

  # Install Docker Engine
  install_docker_engine

  # Verify the Docker Version Installed
  check_version
}

do_main
