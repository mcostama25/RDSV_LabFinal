# RDSV_LabFinal

## Descripción del Proyecto
Este proyecto tiene como objetivo configurar los switches dentro de las KNFs para que sean controlados mediante OpenFlow desde el controlador SDN Ryu. Se busca garantizar la conectividad IPv4 dentro de la red corporativa y su acceso a Internet, además de gestionar la calidad del servicio mediante la API REST de Ryu. Adicionalmente, se implementa la captura de tráfico ARP en las sedes remotas utilizando "arpwatch". Todo el despliegue se encuentra automatizado mediante scripts.

La siguiente figura muestra la arquitectura del escenario utilizado, proporcionando un
esquema de los componentes principales y su interacción dentro de la red. A partir de esta
configuración, se han realizado una serie de cambios que nos han permitido el uso de un
controlador RYU hospedado en una KNF independiente, así como el control de calidad
de servicio QoS mediante el uso de la aplicación qos simpleswitch 13.py o la captura de
tr´afico ARP mediante arpwatch en los routers R1 y R2, entre otros.
<img src="images/arquitecturaRed.png" width="600">


## Características Principales
- Configuración de switches de las KNFs bajo control de OpenFlow desde Ryu.
- Implementación de una nueva KNF con el controlador SDN Ryu.
- Gestión de calidad de servicio en la red de acceso a través de la API REST de Ryu.
- Captura de tráfico ARP en sedes remotas mediante "arpwatch".
- Despliegue para dos sedes con automatización mediante scripts.
- Sustitución de repositorios por repositorios propios de los alumnos:
  - Contenedor Docker de las KNFs en DockerHub (migración de cuenta "educaredes" a cuenta de alumno).
  - Reemplazo del repositorio Helm local con un servidor web local lanzado con Docker.
- Creación de la imagen del contenedor Docker que alojará el controlador Ryu.
- Creación y modificación de descriptores:
  - Helm charts.
  - KNF: ctrl.
  - Servicio sdedge-qos.

  La siguiente imágen muestra los distintos servicios configurados desntro de cada uno de las Centrales de proximidad mediante Kubernetes Network Functions (KNF).
  <img src="images/arquitecturaServicios.png" width="600">


## Requisitos Previos
Para desplegar el entorno correctamente, se necesitan los siguientes requisitos:
- Docker y Docker-Compose instalados.
- Helm instalado para la gestión de los charts.
- Open vSwitch (OVS) configurado para trabajar con OpenFlow.
- Ryu Controller instalado en el contenedor correspondiente.
- Acceso a DockerHub y repositorios privados de los alumnos.

## Instalación y Configuración
1. **Clonar el repositorio:**
   ```sh
   git clone https://github.com/mcostama25/RDSV_LabFinal.git
   cd RDSV_LabFinal
   ```
2. **Construcción de la imagen Docker para Ryu Controller:**
   ```sh
   docker build -t usuario/ryu-controller .
   ```
3. **Desplegar la infraestructura utilizando Docker-Compose:**
   ```sh
   docker-compose up -d
   ```
4. **Verificar la conectividad y la gestión de calidad de servicio:**
   - Acceder a la API REST de Ryu y comprobar el estado de los switches.
   - Ejecutar pruebas de conectividad IPv4 entre las sedes y hacia Internet.

## Uso
Una vez desplegado el entorno, el controlador Ryu gestionará el tráfico de la red. Se puede verificar su estado mediante la API REST:
```sh
curl http://localhost:8080/stats/switches
```

Para monitorear el tráfico ARP capturado en las sedes remotas:
```sh
tail -f /var/log/arpwatch.log
```


