#!/bin/sh

# Kubernetes Cluster Cert 

# The default certificate period for kubernetes is 1 year.
# If the certificate expires, Kubernetes will not work and an extension is required.

menu=0
defaultIP=172.30.0.2
clusterIP=0.0.0.0

checkCreationDate() {
  echo "\e[1;31mCheck Kubernetes Cluster Certificate Initial Creation Date \e[0m"

  echo "\e[34mAPIServer Cert \e[0m"
  openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates

  echo "\e[34mAPIServer Kubelet Client Cert \e[0m"
  openssl x509 -in /etc/kubernetes/pki/apiserver-kubelet-client.crt -noout -dates

  echo "\e[34mAPIServer ETCD Client Cert \e[0m"
  openssl x509 -in /etc/kubernetes/pki/apiserver-etcd-client.crt -noout -dates

  echo
}

checkExpirationDate() {
  echo "\e[1;31mCheck Kubernetes Cluster Certificate Expiration Date \e[0m"
  kubeadm certs check-expiration

  echo
}

reNewCert() {
  echo "\e[1;31mUpdate Kubernetes Cluster Certificate \e[0m"
  kubeadm certs renew all

  echo
}

reCreateCert() {
  echo "\e[1;31mRecreate Kubernetes Cluster Certificate \e[0m"
  echo "If you remove Certificates, recreates certificates through this process"
  echo "Cluster IP - $clusterIP"
  read -p "If not right, Change Cluster IP? [y/n] : " ox
  echo

  if [ $ox = 'Y' ] || [ $ox = 'y' ]; then
    echo "Input New Cluster IP :"
    read clusterIP
  else
    echo "Keep it as it is."
  fi
  echo "Cluster IP : $clusterIP"

  kubeadm init phase certs apiserver --apiserver-cert-extra-sans '$clusterIP'
  kubeadm init phase certs apiserver-kubelet-client
  kubeadm init phase certs apiserver-etcd-client

  echo
}

main() {
  clusterIP=$(kubectl cluster-info | awk -F ://  'NR<2 {print $2}' | awk -F : '{print $1}')
  echo
  if [ -z "$clusterIP" ]; then
    echo "Could not find cluster IP. Set Default IP"
    clusterIP=$defaultIP
  fi
  echo "\e[1;34mCluster IP : $clusterIP\e[0m"

  while [ 1 ]
    do
      echo "\e[36m-------------------------------------------------------------------\e[0m"
      echo "Check and Update Kubernetes Cluster Certificate "
      echo "1. Check Kubernetes Cluster Certificate Initial Creation Date"
      echo "2. Check Kubernetes Cluster Certificate Expiration Date"
      echo "3. Update Kubernetes Cluster Certificate Date"
      echo "4. Recreate Kubernetes Cluster Certificate"
      echo "0. Exit"
      echo "\e[36m-------------------------------------------------------------------\e[0m"

      read -p "Input the operation number : " oper
      if [ $oper -lt 0 ] || [ $oper -gt 4 ]; then
        echo "\e[1;31mWrong Value!\e[0m"
        echo
        continue
      fi
      echo

      case $oper in
        1)
          checkCreationDate
          ;;
        2)
          checkExpirationDate
          ;;
        3)
          reNewCert
          ;;
        4)
          reCreateCert
          ;;
        0)
          echo "Exit"
          echo
          break
          ;;
      esac
  done
}

main

exit 0
