FROM osrg/ryu
COPY README.txt README.txt
COPY ./qos_simple_switch_13.py qos_simple_switch_13.py
COPY ./simple_switch_13.py simple_switch_13.py
RUN apt-get clean
RUN apt-get update && \
    apt-get install -y \
    net-tools \
    iproute2 \
    inetutils-ping \
    openvswitch-switch \
    openvswitch-common \
    tcpdump \
    iperf \
    git \
    python-pip 
EXPOSE 6633
RUN git clone https://github.com/martimy/flowmanager

