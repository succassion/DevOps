#!/bin/sh

# Docker CE for Linux installation script
#
# See https://docs.docker.com/engine/install/ for the installation steps.
#

# Enter Version
input=${1}

echo "\e[31mInstall Kubernetes\e[0m"

# Global Value
KUBERNETES_VERSION=NULL


# Verify Kubernetes Version To be Install
enter_version() {
  echo "Input Version : $input"

  if [ -z "$input" ]; then
    KUBERNETES_VERSION="1.23.5-00"
  else
    KUBERNETES_VERSION=$input
  fi

  echo
  echo "Kubernetes Version :" "\e[31m $KUBERNETES_VERSION \e[0m"
}


# Swap Disabled
disabled_swap() {
  echo
  echo
  echo "\e[36m1. Disabled Swap \e[0m"

  echo "1) Check Swapoff"
  swapon -s

  echo
  echo "2) Set SwapOff"
  tmp=$(swapon -s)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Already SwapOff. \e[0m"
  else 
    echo "\e[33m- Set SwapOff. \e[0m"
    swapoff -a
  fi

  echo
  echo "3) Block swapfile"
  tmp=$(cat /etc/fstab | grep "#/swapfile")
  if [ -z "$tmp" ]; then
    echo "\e[33m- Set fstab file. \e[0m"
    sed -i '/swap/s/^/#/' /etc/fstab
  else
    echo "\e[33m- Already Set fstab file. \e[0m"
  fi
}


# Check Bridged Netfilter
br_netfilter() {
  echo
  echo
  echo "\e[36m2. Check Bridged Netfilter \e[0m"
  echo "1) Check Bridged Netfilter Setting"
  tmp=$(find /etc/modules-load.d/ -name k8s.conf)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Set Bridged Netfilter. \e[0m"
    echo "br_netfilter" >> /etc/modules-load.d/k8s.conf
  else
    tmp=$(grep -rin "br_netfilter" /etc/modules-load.d/)
    if [ -z "$tmp" ]; then
      echo "\e[33m- Set Bridged Netfilter. \e[0m"
      echo "br_netfilter" >> /etc/modules-load.d/k8s.conf
    else
      echo "\e[33m- Already Set Bridged Netfilter. \e[0m"
    fi
  fi


  echo
  echo "2) Check Net Bridge"
  tmp=$(find /etc/sysctl.d/ -name k8s.conf)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Set Net Bridge. \e[0m"
    echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
    echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/k8s.conf
  else
    tmp=$(grep -rin "net.bridge.bridge-nf-call-iptables" /etc/sysctl.d/)
    if [ -z "$tmp" ]; then
      echo "\e[33m- Set Net Bridge. \e[0m"
      echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
      echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/k8s.conf
    else 
      echo "\e[33m- Already Set Net Bridge. \e[0m"
    fi
  fi

  echo "\e[33m- Check sysctl \e[0m "
  echo "   net.bridge.bridge-nf-call-iptables = " $(sysctl -n net.bridge.bridge-nf-call-iptables)
  echo "   net.bridge.bridge-nf-call-ip6tables = " $(sysctl -n net.bridge.bridge-nf-call-ip6tables)
}


# Set Docker Daemon
docker_daemon() {
  echo
  echo
  echo "\e[36m3. Set Docker Daemon \e[0m"
  echo "\e[33m- Set Daemon jason file. \e[0m"
  mkdir /etc/docker/
  cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m"
  },
  "storage-driver": "overlay2"
}
EOF

  echo 
  echo "\e[33m- Restart Docker Daemon. \e[0m"
  systemctl enable docker
  systemctl daemon-reload
  systemctl restart docker

  systemctl status kubelet
  systemctl start kubelet

  echo
  echo "\e[33m- Docker Daemon Status. \e[0m"
  systemctl is-active --quiet docker && echo "\e[35mDocker is running.\e[0m" || echo "\e[35mDocker is NOT running.\e[0m"
}


# Download Google Cloud Public signing Key and Set Repository
set_repository() {
  echo
  echo
  echo "\e[36m4. Install APT \e[0m"
  echo "1) Update the apt package index and install packages needed to use the Kubernetes apt repository:"

  echo "\e[33m- Update Package list. \e[0m"
  apt-get update

  echo "\e[33m- Install Package. \e[0m"
  apt-get install -y apt-transport-https ca-certificates curl

  echo "\e[33m3) Download Google Cloud Public signing Key \e[0m"
  tmp=$(find /usr/share/keyrings/ -name kubernetes-archive-keyring.gpg)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Google Cloud Public signing key. \e[0m"
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  else
    echo "\e[33m- Already exists. \e[0m"
  fi

  echo "\e[33m4). Add the Kubernetes apt repository \e[0m"
  tmp=$(find /etc/apt/sources.list.d/ -name kubernetes.list)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Set Kubernetes apt repository. \e[0m"
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  else
    echo "\e[33m- Already Set repository.  \e[0m"
  fi
}


# Install kubelet, kubeadm and kubectl
install_kubernetes() {
  echo
  echo
  echo "\e[36m5. Install kubelet, kubeadm and kubectl \e[0m"
  echo "1) Update Package list"
  apt-get update

  echo
  echo "2) Install kubelet, kubeadm and kubectl"
  apt-get install -y kubelet=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION
  systemctl start kubelet

  echo
  echo "3) Hold apt"
  apt-mark hold kubelet kubeadm kubectl
}


# Verify the Kubernetes Version Installed
check_version() {
  echo
  echo
  echo "\e[36m6. Verify the Kubernetes Version Installed \e[0m"
  tmp=$(kubectl version)
  if [ -z "$tmp" ]; then
    echo "\e[33m- Not properly installed. \e[0m"
  else
    kubectl version --short --client
  fi

  echo
  echo "\e[31m Complete \e[0m"
  echo
}



# Main Function
do_main () {
  # Verify Kubernetes Version To be Install
  enter_version

  # Swap Disabled
  disabled_swap

  # Check Bridged Netfilter
  br_netfilter

  # Set Docker Daemon 
  docker_daemon
  
  # Download Google Cloud Public signing Key and Set Repository
  set_repository

  # Install kubelet, kubeadm and kubectl
  install_kubernetes

  # Verify the Kubernetes Version Installed
  check_version
}

do_main
