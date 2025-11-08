# File: topology/topology.py

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.link import TCLink
from mininet.cli import CLI
from mininet.log import setLogLevel

try:
    from mn_wifi.bmv2 import P4Switch # Standard P4 Switch class in Mininet-WiFi
except ImportError:
    # If this still fails, your Mininet-WiFi install might be missing P4 support.
    print("FATAL: Cannot import P4Switch from mn_wifi.bmv2. Check Mininet-WiFi P4 setup.")
    class P4Switch: pass # Define a placeholder to prevent immediate crash

P4_JSON_FILE = '../config/p4_stm.json'
P4_P4INFO_FILE = '../config/p4_stm.p4info.txt'
NETCFG_FILE='../../onos/netcfg/netcfg.json'

class STMTopo(Topo):
    def build(self):
        h1 = self.addHost('h1', ip='10.0.1.1/24')
        h2 = self.addHost('h2', ip='10.0.2.2/24')

        s1 = self.addSwitch('s1', 
                            cls=P4Switch,
                            json_path=P4_JSON_FILE,
                            p4info=P4_P4INFO_FILE,
                            grpcport=9559, # Example port
                            thriftport=10001,
                            netcfg=NETCFG_FILE,
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
