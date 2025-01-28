#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

KUBECTL="microk8s kubectl"

VACC_1="deploy/access1-accesschart"
VCPE_1="deploy/cpe1-cpechart"
VWAN_1="deploy/wan1-wanchart"
VCTRL_1="deploy/ctrl1-ctrlchart" # añadido para la knf CTRL

VACC_2="deploy/access2-accesschart"
VCPE_2="deploy/cpe2-cpechart"
VWAN_2="deploy/wan2-wanchart"
VCTRL_2="deploy/ctrl2-ctrlchart" # añadido para la knf CTRL

ACC_1_EXEC="$KUBECTL exec -n $SDWNS $VACC_1 --"
CPE_1_EXEC="$KUBECTL exec -n $SDWNS $VCPE_1 --"
WAN_1_EXEC="$KUBECTL exec -n $SDWNS $VWAN_1 --"
CTRL_1_EXEC="$KUBECTL exec -n $SDWNS $VCTRL_1 --"

ACC_2_EXEC="$KUBECTL exec -n $SDWNS $VACC_2 --"
CPE_2_EXEC="$KUBECTL exec -n $SDWNS $VCPE_2 --"
WAN_2_EXEC="$KUBECTL exec -n $SDWNS $VWAN_2 --"
CTRL_2_EXEC="$KUBECTL exec -n $SDWNS $VCTRL_2 --"


echo "## 1. Obtener IPs de las VNFs"

export IPACCESS_1=`$ACC_1_EXEC hostname -I | awk '{print $1}'`
echo "IPACCESS_1 = $IPACCESS_1"
export IPCPE_1=`$CPE_1_EXEC hostname -I | awk '{print $1}'`
echo "IPCPE_1 = $IPCPE_1"
export IPWAN_1=`$WAN_1_EXEC hostname -I | awk '{print $1}'`
echo "IPWAN_1 = $IPWAN_1"
export IPCTRL_1=`$CTRL_1_EXEC hostname -I | awk '{print $1}'` # añadido para la knf de CTRL
echo "IPCTRL_1 = $IPCTRL_1"

export IPACCESS_2=`$ACC_2_EXEC hostname -I | awk '{print $1}'`
echo "IPACCESS_2 = $IPACCESS_2"
export IPCPE_2=`$CPE_2_EXEC hostname -I | awk '{print $1}'`
echo "IPCPE_2 = $IPCPE_2"
export IPWAN_2=`$WAN_2_EXEC hostname -I | awk '{print $1}'`
echo "IPWAN_2 = $IPWAN"
IPCTRL_2=`$CTRL_2_EXEC hostname -I | awk '{print $1}'` # añadido para la knf de CTRL
echo "IPCTRL_2 = $IPCTRL_2"

sw=0000000000000003
echo -e "$yellowColour [!] Curl para ver las colas en el RYU de la sede 1 $endColour"

curl -s http://$IPCTRL_1:8080/qos/queue/$sw | jq

sleep 1

echo -e "$yellowColour [!] Curl para ver las reglas en el RYU de la sede 1"

curl -s http://$IPCTRL_1:8080/qos/rules/$sw | jq

sleep 3

echo -e "$yellowColour [!] Curl para ver las colas en el RYU de la sede 2 $endColour"

curl -s http://$IPCTRL_2:8080/qos/queue/$sw | jq

sleep 1

echo -e "$yellowColour [!] Curl para ver las reglas en el RYU de la sede 2"

curl -s http://$IPCTRL_2:8080/qos/rules/$sw | jq

