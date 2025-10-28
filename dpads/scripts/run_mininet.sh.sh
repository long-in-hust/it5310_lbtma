#!/bin/bash

# Set up directory paths
P4_SRC_DIR="../p4src"
CONFIG_DIR="../config"
TOPOLOGY_SCRIPT="../topology/topology.py"
CONTROLLER_SCRIPT="../control/controller.py"

# Filenames
P4_FILE="dpads.p4"
JSON_FILE="dpads.json"
P4INFO_FILE="dpads.p4info.txt"

# Step 1: Compile the P4 program
echo "Compiling P4 program..."
p4c-bm2-ss \
  --target bmv2 \
  --arch v1model \
  --std p4-16 \
  --p4runtime-files ${CONFIG_DIR}/${P4INFO_FILE} \
  -o ${CONFIG_DIR}/${JSON_FILE} \
  ${P4_SRC_DIR}/${P4_FILE}

if [ $? -ne 0 ]; then
  echo "❌ P4 compilation failed."
  exit 1
fi
echo "✅ P4 compilation successful."

# Step 2: Start the BMv2 switch with gRPC server
echo "Starting BMv2 simple_switch_grpc..."
sudo simple_switch_grpc \
  --device-id 0 \
  --log-console \
  -i 0@veth0 \
  -i 1@veth1 \
  -i 2@veth2 \
  -- --cpu-port 255 \
  ${CONFIG_DIR}/${JSON_FILE} &

sleep 2

# Step 3: Launch Mininet topology
echo "Launching Mininet topology..."
sudo python3 ${TOPOLOGY_SCRIPT} &

sleep 2

# Step 4: Run the controller to configure the switch
echo "Running P4Runtime controller..."
python3 ${CONTROLLER_SCRIPT}

# Cleanup on exit
trap "pkill -f simple_switch_grpc; pkill -f topology.py; echo 'Cleaned up background processes.'" EXIT
