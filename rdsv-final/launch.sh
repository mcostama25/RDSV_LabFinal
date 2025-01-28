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

function ctrl_c(){
	echo -e "\n [+] $redColour [!] Saliendo..! $endColour \n"
	tput cnorm && exit 1
}

#Ctrl+C
trap ctrl_c INT


function helpPanel(){
	echo -e "\n${redColour}[!]$endColour Uso del script: "
	echo -e "\t${purpleColour}d)$endColour $grayColour Levantar serviudor Docker para repositotio helm. $endColour\n"
	echo -e "\t${purpleColour}v)$endColour $grayColour Levantar escenario VNX. $endColour\n"
	echo -e "\t${purpleColour}n)$endColour $grayColour Sedes a levantar: 1 (sede 1), 2 (sede 2) 3 (las dos)) $endColour\n"
	echo -e "\t${purpleColour}s)$endColour $grayColour Arrancar servicio SDEDGE. $endColour\n"
	echo -e "\t${purpleColour}w)$endColour $grayColour Arrancar servicio SDWAN y RYU. $endColour\n"

}


function HelmServer(){

	echo -e "\n$yellowColour[+]$endColour Levantando servidor helm. \n"
	docker stop $(docker ps -q)
	docker rm $(docker ps -a -q)
	docker run --name helm-repo -p 8080:80 -v /home/upm/Documents/helm-files/:/usr/share/nginx/html:ro -d nginx

	echo -e "$greenColour[+] Servidor helm-repo listo!$endColour"

}

function VNX(){

	echo -e "\n$yellowColour[+]$endColour Arrancando escenario VNX \n"
	sudo vnx -f ./vnx/sdedge_nfv.xml --destroy
	sudo vnx -f ./vnx/sdedge_nfv.xml -t
	echo -e "$greenColour[+] Escenario listo!$endColour"

}

function sede_remota(){

	Num=$1

	if [ $Num -eq 1 ]; then
		echo -e "\n$yellowColour[+]$endColour Arrancando sede remota 1."
		./sdedge1.sh
		./bin/sdw-knf-consoles open 1

	elif [ $Num -eq 2 ]; then
		echo -e "\n$yellowColour[+]$endColour Arrancando sede remota 2."
		./sdedge2.sh
		./bin/sdw-knf-consoles open 2

	elif [ $Num -eq 3 ]; then
		echo -e "\n$yellowColour[+]$endColour Arrancando ambas sedes remotas. "
		./sdedge1.sh
		./bin/sdw-knf-consoles open 1

		./sdedge2.sh
		./bin/sdw-knf-consoles open 2
	fi

	echo -e "$greenColour[+] Sedes remotas listas!$endColour"

}

function sdWan(){
	
	Num=$1

	if [ $Num -eq 1 ]; then
		echo -e "$yellowColour[+]$endColour Arrancando servicio SDWAN1."
		./sdwan1.sh

	elif [ $Num -eq 2 ]; then
		echo -e "$yellowColour[+]$endColour Arrancando servicio SDWAN2."
		./sdwan2.sh
		
	elif [ $Num -eq 3 ]; then
		echo -e "$yellowColour[+]$endColour Arrancando servicion SDWAN1 y SDWAN2. "
		./sdwan1.sh
		./sdwan2.sh
	fi

	echo -e "$greenColour[+] Servicions SDWAN listos!$endColour"

}


# Indicadors
#
declare -i docker_val=0
declare -i vnx_val=0
declare -i Num=0
declare -i remote_site=0
declare -i wan_site=0
declare -a functions_to_run=()

# Definición de los argumentos
while getopts "dvn:swh" arg; do
    case $arg in
        d) functions_to_run+=("HelmServer");;
        v) functions_to_run+=("VNX");;
        n) Num=$OPTARG;;
        s) functions_to_run+=("sede_remota");;
        w) functions_to_run+=("sdWan");;
        h) helpPanel; exit 0;;
    esac
done

# Ejecución de las funciones en el orden indicado
for func in "${functions_to_run[@]}"; do
    if [[ "$func" == "sede_remota" || "$func" == "sdWan" ]]; then
        $func $Num
    else
        $func
    fi
done

# Si no se pasaron opciones, mostrar ayuda
if [ ${#functions_to_run[@]} -eq 0 ]; then
    helpPanel
fi