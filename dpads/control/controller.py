# File: control/controller.py
"""
Control Plane for P4-DPADS Module
Uses P4Runtime to install forwarding and aggregation rules into BMv2
"""

import sys
import grpc
import os
import time
from p4runtime_lib.switch import ShutdownAllSwitchConnections
from p4runtime_lib.helper import P4InfoHelper

P4INFO_PATH = "../p4/dpads.p4info.txt"
JSON_PATH = "../config/dpads.json"


def write_aggregation_rules(p4info_helper, sw):
    # Set aggregation rule based on totalLen < 500
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.aggregation_control",
        match_fields={},  # No specific match: apply to all
        action_name="MyIngress.increment_pkt_count",
        action_params={}
    )
    sw.WriteTableEntry(table_entry)
    print("Installed aggregation rule.")


def write_forwarding_rules(p4info_helper, sw):
    table_entry = p4info_helper.buildTableEntry(
        table_name="MyIngress.forwarding_table",
        match_fields={
            "hdr.ipv4.dstAddr": ("10.0.2.2", 32)
        },
        action_name="MyIngress.forward",
        action_params={
            "port": 2
        }
    )
    sw.WriteTableEntry(table_entry)
    print("Installed forwarding rule for 10.0.2.2 -> port 2")


def main():
    p4info_helper = P4InfoHelper(P4INFO_PATH)

    try:
        sw = p4info_helper.buildSwitchConnection(
            name="s1",
            address="127.0.0.1:50051",
            device_id=0,
            proto_dump_file="logs/s1-p4runtime-requests.txt"
        )
        sw.MasterArbitrationUpdate()

        sw.SetForwardingPipelineConfig(p4info=p4info_helper.p4info,
                                       bmv2_json_file_path=JSON_PATH)

        write_aggregation_rules(p4info_helper, sw)
        write_forwarding_rules(p4info_helper, sw)

    except KeyboardInterrupt:
        print("Interrupted")
    except grpc.RpcError as e:
        printGrpcError(e)
    finally:
        ShutdownAllSwitchConnections()


if __name__ == '__main__':
    main()
