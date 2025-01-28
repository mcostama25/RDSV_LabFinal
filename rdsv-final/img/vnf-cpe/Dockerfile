FROM educaredes/vnf-access
# install required packages
COPY README.txt README.txt
COPY ../qos_simple_switch_13.py qos_simple_switch_13
RUN apt-get clean
RUN apt-get update \
    && apt-get install -y \
    iptables 

COPY vnx_config_nat vnx_config_nat

RUN chmod +x vnx_config_nat

