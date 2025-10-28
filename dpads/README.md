
# 🧠 P4-DPADS Module: Distributed Packet Aggregation and Disaggregation System

This repository provides the complete implementation and deployment guide for the P4-DPADS module, a key component of the **LBTMA framework** for SD-IoT networks.

## 📁 Directory Structure

```
P4-DPADS/
├── p4/
│   └── dpads.p4                  # P4 program source
├── config/
│   └── dpads.json                # Compiled BMv2 JSON output
│   └── dpads.p4info.txt          # Runtime info file for P4Runtime
├── control/
│   └── controller.py             # Control plane logic (P4Runtime)
├── topology/
│   └── topology.py               # Mininet topology
├── scripts/
│   └── run_mininet.sh            # Launcher script
└── README.md
```

## 🧪 Dependencies

Install the following tools:

- `p4c` (P4 Compiler): v1.3.0+
- `BMv2` (Behavioral Model 2): latest
- `Mininet` or `Mininet-WiFi`
- `Python3`, `grpcio`, `protobuf`, `p4runtime_lib`
- `iperf3`, `hping3`, `tcpdump`, `tshark`

## 🚀 Emulation Setup (Mininet)

### Step 1: Compile the P4 Program

```bash
p4c-bm2-ss --target bmv2 --arch v1model \
  --p4runtime-files config/dpads.p4info.txt \
  -o config/dpads.json p4/dpads.p4
```

### Step 2: Launch Full Emulation

```bash
cd scripts
chmod +x run_mininet.sh
./run_mininet.sh
```

This launches:

- BMv2 `simple_switch_grpc` with compiled `dpads.json`
- A custom topology with 1 switch, 2 hosts
- Control plane script (`controller.py`) to configure forwarding & aggregation logic

## 🎯 Features

- ✅ Custom IoT header (`device_id`, `payload_type`, `timestamp`)
- ✅ Hierarchical packet aggregation: triggered on packet count threshold
- ✅ Stateful disaggregation logic via registers and metadata
- ✅ Configurable forwarding and drop actions
- ✅ Example rules installed by control plane

## 📈 Traffic Generation

### Example Tests

```bash
# From h1 to h2
iperf3 -s    # On h2
iperf3 -c 10.0.2.2 -t 10  # On h1

# Simulate alert traffic with hping3
hping3 -S 10.0.2.2 -p 80 --flood
```

## 🧱 Real Hardware Deployment (e.g., Tofino Switch)

1. Compile `dpads.p4` with Barefoot SDE
2. Use ONOS to configure intents and policies
3. Load `dpads.json` and `dpads.p4info.txt`
4. Map ports and flow tables using ONOS CLI
5. Verify packet flow with real IoT traffic

## 🧾 Citation

If you use this module, please cite:

> LBTMA: An Integrated P4-Enabled Framework for Optimized Traffic Management in SD-IoT Networks, 2024.

