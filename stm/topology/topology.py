# File: topology/topology.py

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.link import TCLink
from mininet.cli import CLI
from mininet.log import setLogLevel

try:
    from p4runtime_switch import P4RuntimeSwitch
except ImportError:
    # Fallback/Error handling if the module is not in the path
    print("FATAL: Cannot import P4RuntimeSwitch. Ensure the P4 environment is sourced.")
    # Define a simple placeholder to prevent immediate crash, though topology will fail later
    class P4RuntimeSwitch: pass

P4_JSON_FILE = '../config/p4_stm.json'
P4_P4INFO_FILE = '../config/p4_stm.p4info.txt'

class STMTopo(Topo):
    def build(self):
        h1 = self.addHost('h1', ip='10.0.1.1/24')
        h2 = self.addHost('h2', ip='10.0.2.2/24')

        s1 = self.addSwitch('s1', 
                            cls=P4RuntimeSwitch, 
                            json_path=P4_JSON_FILE,
                            p4info=P4_P4INFO_FILE,
                            grpc_port=9559, # Example port
                            device_id=0)

        self.addLink(h1, s1, cls=TCLink, bw=10, delay='5ms')
        self.addLink(h2, s1, cls=TCLink, bw=10, delay='5ms')


def run():
    topo = STMTopo()
    net = Mininet(topo=topo, controller=None, autoSetMacs=True)
    net.addController('c0', controller=RemoteController, ip='127.0.0.1', port=6653)

    net.start()
    print("\n--- Running Mininet CLI ---")
    CLI(net)
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    run()
