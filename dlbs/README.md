# ⚖️ P4-DLBS: Distributed Load Balancing System

This module implements the Enhanced Weighted Round Robin (EWRR) logic using P4 and P4Runtime for scalable load balancing in SD-IoT networks.

## 🔧 Components

- `p4dlbs/p4_dlbs.p4`: P4 program for load distribution logic
- `controller/controller_dlbs.py`: Runtime server selection with P4Runtime
- `topology/topology_dlbs.py`: Mininet test topology with 3 servers
- `scripts/run_mininet_dlbs.sh`: Automation script

## 🚀 Running

```bash
chmod +x scripts/run_mininet_dlbs.sh
./scripts/run_mininet_dlbs.sh
```

## 📘 Algorithm Reference

Implements P4-EWRR algorithm (Algorithm 2 in LBTMA paper) with real-time coordination across P4 switches using queue lengths and server stats.

## 🛠 Requirements

- P4C, BMv2
- Python 3.6+
- Mininet
- gRPC, Protobuf

## 📊 Results

P4-DLBS achieves:
- 15 ms average response time
- 900 Mbps throughput
- 2% packet drop

See paper for full evaluation results.
