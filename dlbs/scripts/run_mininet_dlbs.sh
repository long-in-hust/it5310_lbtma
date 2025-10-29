#!/bin/bash
set -e

# Change directory to that containing the script
cd "$(dirname "$0")"

mkdir -p ../build

echo "Compiling p4_dlbs.p4..."
p4c --target bmv2 --arch v1model --std p4-16 -o ../build/p4_dlbs.json ../p4src/p4_dlbs.p4

sudo simple_switch --log-console --thrift-port 9090 ../build/.json

echo "Launching Mininet topology..."
sudo python3 ../topology/topology_dlbs.py &
sleep 5

echo "Starting controller..."
python3 ../controller/controller_dlbs.py
