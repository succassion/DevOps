#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

ALLN="all-namespaces"

echo ================================================
echo Select Monitoring Pod
echo ------------------------------------------------
echo "${YELLOW}If you don't input it, Be monitor All NameSpaces${NC}"
echo ------------------------------------------------
echo select below one namesapces
kubectl get ns
echo ------------------------------------------------
echo Enter: 
read INPUTPOD

if [ -z "$INPUTPOD" ]; 
then
    CMD="kubectl get pods -o wide --all-namespaces"
    INPUTPOD=all-namespaces
else
    CMD="kubectl get pods -o wide -n ${INPUTPOD}"
fi


while : 
do 
	clear
	echo "Kubenetes Pod Monitoring" "${RED}$INPUTPOD${NC}" "(5sec)" 
        ${CMD}
	sleep 5
done
