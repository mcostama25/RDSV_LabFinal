FROM      osrg/ryu
COPY README.txt README.txt
COPY ../qos_simple_switch_13.py qos_simple_switch_13
RUN apt-get clean
RUN	apt-get update && apt-get install -y \
	net-tools \
	iproute \
	inetutils-ping \
    openvswitch-switch \
    openvswitch-common \
    iperf \
    tcpdump \
    python-pip \
    git

#RUN pip install -r ryu/tools/optional-requires
RUN git clone https://github.com/martimy/flowmanager
