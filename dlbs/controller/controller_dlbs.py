# Controller logic for P4-DLBS using P4Runtime
from p4runtime_lib.helper import P4InfoHelper
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.bmv2
import time

p4info_helper = P4InfoHelper("../build/p4_dlbs.p4info.txt")

switch = p4runtime_lib.bmv2.Bmv2SwitchConnection(
    name='s1', address='127.0.0.1:50051', device_id=0,
    proto_dump_file='logs/s1-p4runtime-requests.txt'
)
switch.MasterArbitrationUpdate()
switch.SetForwardingPipelineConfig(
    p4info=p4info_helper.p4info,
    bmv2_json_file_path="../build/p4_dlbs.json"
)
print("Installed P4 pipeline.")

# Future: Insert server selection logic here
ShutdownAllSwitchConnections()
