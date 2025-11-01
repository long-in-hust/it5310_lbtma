#!/bin/bash

# Set paths
P4SRC=../p4_src/p4_stm.p4
JSON=../config
JSON_IMMEDIATE=../config/p4_stm.jsons
P4INFO=../config/p4_stm.p4info.txt

# Change directory to that containing the script
cd "$(dirname "$0")"

# Compile P4 program
echo "Compiling P4 program..."
p4c --target bmv2 --arch v1model --p4runtime-files $P4INFO --std p4-16 -o $JSON $P4SRC
# p4c --target bmv2 --arch v1model --p4runtime-files config/p4_stm.p4info.txt --std p4-16 -o ./config p4_src/p4_stm.p4

# Launch BMv2 switch
echo "Starting BMv2 switch with gRPC..."
simple_switch_grpc --device-id 0 --log-console -i 0@veth0 -i 1@veth1 $JSON_IMMEDIATE &

# Debug command:
# sudo simple_switch_grpc --device-id 0 --log-console -i 0@veth0 -i 1@veth1 config/p4_stm.json/p4_stm.json

sleep 2

# Launch controller (Python gRPC)
# echo "Launching P4Runtime controller..."
# cd ../control
# python3 controller.py &
# cd -
# sleep 2

# Launch Mininet topology
echo "Starting Mininet..."
sudo python3 ../topology/topology.py
# sudo python3 topology.py

# Clean up background processes on exit
trap "killall simple_switch_grpc; killall python3" EXIT
