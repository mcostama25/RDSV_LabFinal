#!/bin/bash

# Requires the following variables
# KUBECTL: kubectl command
# SDWNS: cluster namespace in the cluster vim
# NETNUM: used to select external networks
# VCPE: "pod_id" or "deploy/deployment_id" of the cpd vnf
# VWAN: "pod_id" or "deploy/deployment_id" of the wan vnf
# REMOTESITE: the "public" IP of the remote site

set -u # to verify variables are defined
: $KUBECTL
: $SDWNS
: $NETNUM
: $VCPE
: $VCTRL
: $VWAN
: $REMOTESITE

if [[ ! $VACC =~ "-accesschart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <access_deployment_id>: $VACC"
    exit 1
fi

if [[ ! $VCPE =~ "-cpechart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <cpe_deployment_id>: $VCPE"
    exit 1
fi

if [[ ! $VWAN =~ "-wanchart"  ]]; then
   echo ""       
   echo "ERROR: incorrect <wan_deployment_id>: $VWAN"
   exit 1
fi

if [[ ! $VCTRL =~ "-ctrlchart"  ]]; then
   echo ""       
   echo "ERROR: incorrect <ctrl_deployment_id>: $VCTRL"
   exit 1
fi

ACC_EXEC="$KUBECTL exec -n $SDWNS $VACC --"
CPE_EXEC="$KUBECTL exec -n $SDWNS $VCPE --"
WAN_EXEC="$KUBECTL exec -n $SDWNS $VWAN --"
CTRL_EXEC="$KUBECTL exec -n $SDWNS $VCTRL --" # ejecutar comandos desde la KNF de control (RYU conytroller)

WAN_SERV="${VWAN/deploy\//}"
CTRL_SERV="${VCTRL/deploy\//}"
ACC_SERV="${VACC/deploy\//}"



# Router por defecto inicial en k8s (calico)
K8SGW="169.254.1.1"

## 1. Obtener IPs y puertos de las VNFs
echo "## 1. Obtener IPs y puertos de las VNFs"

IPCPE=`$CPE_EXEC hostname -I | awk '{print $1}'`
echo "IPCPE = $IPCPE"

IPWAN=`$WAN_EXEC hostname -I | awk '{print $1}'`
echo "IPWAN = $IPWAN"

IPCTRL=`$CTRL_EXEC hostname -I | awk '{print $1}'` # añadido para la knf de CTRL
echo "IPCTRL = $IPCTRL"

IPACCESS=`$ACC_EXEC hostname -I | awk '{print $1}'`
echo "IPACCESS = $IPACCESS"

PORTWAN=`$KUBECTL get -n $SDWNS -o jsonpath="{.spec.ports[0].nodePort}" service $WAN_SERV`
PORTCTRL=`$KUBECTL get -n $SDWNS -o jsonpath="{.spec.ports[0].nodePort}" service $CTRL_SERV`
PORTACC=`$KUBECTL get -n $SDWNS -o jsonpath="{.spec.ports[0].nodePort}" service $ACC_SERV`



echo "PORTWAN = $PORTWAN"
echo "PORTCTRL = $PORTCTRL"
echo "PORTACC = $PORTACC"

export IPWAN$NETNUM=$IPWAN
export IPCTRL$NETNUM=$IPCTRL
export IPACCESS$NETNUM=$IPACCESS
export PORTWAN$NETNUM=$PORTWAN
export PORTCTRL$NETNUM=$PORTCTRL
export PORTACC$NETNUM=$PORTACC


## 2. En VNF:cpe agregar un bridge y sus vxlan
echo "## 2. En VNF:cpe agregar un bridge y configurar IPs y rutas"
$CPE_EXEC ip route add $IPWAN/32 via $K8SGW
$CPE_EXEC ip route add $IPCTRL/32 via $K8SGW
$CPE_EXEC ovs-vsctl add-br brwan
$CPE_EXEC ip link add cpewan type vxlan id 5 remote $IPWAN dstport 8741 dev eth0 # link cap a VNF:WAN
$CPE_EXEC ovs-vsctl add-port brwan cpewan
$CPE_EXEC ifconfig cpewan up
$CPE_EXEC ip link add sr1sr2 type vxlan id 12 remote $REMOTESITE dstport 8742 dev net$NETNUM # link cap a Sede remota 2. CORPORATE INTER-SITE vxlan
$CPE_EXEC ovs-vsctl add-port brwan sr1sr2
$CPE_EXEC ifconfig sr1sr2 up

## 3. En VNF:CTRL arrancar controlador SDN"
echo "## 3. En VNF:CTRL arrancar controlador SDN"
$CTRL_EXEC chmod +x ./qos_simple_switch_13.py
$CTRL_EXEC /usr/local/bin/ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch  ./qos_simple_switch_13.py ryu.app.ofctl_rest flowmanager/flowmanager.py &>/dev/null | tee ryu.log &


## 4. Activar el modo SDN del conmutador BRWAN en las 3 KNF 
echo "## 4. En las 3 VNF activar el modo SDN del conmutador"
$WAN_EXEC ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$WAN_EXEC ovs-vsctl set-fail-mode brwan secure
$WAN_EXEC ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000001
$WAN_EXEC ovs-vsctl set-controller brwan tcp:$IPCTRL:6633 # nos permite gestionar el estado global de OVS mediante la API de ryu. pe: añadir QOS, o modificarlas en tiempo real.

## 4 bis. Añadir vxlan entre cpe y wan
echo "## 5. Añadir, en VNF:WAN, vxlan a CPE."
$WAN_EXEC ip link add cpewan type vxlan id 5 remote $IPCPE dstport 8741 dev eth0 # link cap a CPE
$WAN_EXEC ovs-vsctl add-port brwan cpewan
$WAN_EXEC ifconfig cpewan up

$CPE_EXEC ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$CPE_EXEC ovs-vsctl set-fail-mode brwan secure
$CPE_EXEC ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000002
$CPE_EXEC ovs-vsctl set-controller brwan tcp:$IPCTRL:6633 # nos permite gestionar el estado global de OVS mediante la API de ryu. pe: añadir QOS, o modificarlas en tiempo real.

$ACC_EXEC ovs-vsctl set bridge brwan protocols=OpenFlow10,OpenFlow12,OpenFlow13
$ACC_EXEC ovs-vsctl set-fail-mode brwan secure
$ACC_EXEC ovs-vsctl set bridge brwan other-config:datapath-id=0000000000000003
$ACC_EXEC ovs-vsctl set-controller brwan tcp:$IPCTRL:6633 # nos permite gestionar el estado global de OVS mediante la API de ryu. pe: añadir QOS, o modificarlas en tiempo real.

## 5. Aplica las reglas de la sdwan con ryu
echo "## 5. Aplica las reglas de la sdwan con ryu"
RYU_ADD_URL="http://localhost:$PORTCTRL/stats/flowentry/add"  # s'haurà de canviar el port pel de KNF_CTRL (crec)
curl -X POST -d @json/from-cpe.json $RYU_ADD_URL
curl -X POST -d @json/to-cpe.json $RYU_ADD_URL
curl -X POST -d @json/broadcast-from-axs.json $RYU_ADD_URL
curl -X POST -d @json/from-mpls.json $RYU_ADD_URL
curl -X POST -d @json/to-voip-gw.json $RYU_ADD_URL  # G21 sede_remota --> VoIP_GW (global = 3.6Mbps p:5005 = 2400 Mbps)
curl -X POST -d @json/sdedge$NETNUM/to-voip.json $RYU_ADD_URL

echo "--"
echo "sdedge$NETNUM: abrir navegador para ver sus flujos Openflow:"
echo "firefox http://localhost:$PORTCTRL/home/ &"

echo -e "\n [+] Hacemos curl al controlador para ver su esado:"
curl -s http://$IPCTRL:8080/stats/switches | jq


## 6. Aplicar QoS
$ACC_EXEC ovs-vsctl set-manager ptcp:6633
sleep 5 # provar con sleep mayor

echo -e "\n [+] Aplicar las rglas de QoS con la API de ryu. \n"
echo -e "[+] curl PUT \n"
curl -X PUT -d "\"tcp:$IPACCESS:6633\"" http://$IPCTRL:8080/v1.0/conf/switches/0000000000000003/ovsdb_addr


sleep 5

echo -e "[+] curl POST 1 \n"
curl -X POST -d @json/QoS_G21.json http://$IPCTRL:8080/qos/queue/0000000000000003 | jq

sleep 3

echo -e "[+] curl POST 2 \n"
curl -X POST -d @json/Rules_G21.json http://$IPCTRL:8080/qos/rules/0000000000000003 | jq # asignamos la cola 1 al tráfico UDP con destino VoIP-gw

sleep 3

echo -e "[+] Confirmamos que se ha añadido correctamente la QoS:"
curl -X GET http://$IPCTRL:8080/qos/rules/0000000000000003 | jq

