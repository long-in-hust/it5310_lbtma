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

class STMTopo(Topo):
    def build(self):
        h1 = self.addHost('h1', ip='10.1.1.1/24')
        h2 = self.addHost('h2', ip='10.1.2.2/24')

        s1 = self.addSwitch('s1',
                            cls=P4Switch,
                            json_path=P4_JSON_FILE,
                            p4info=P4_P4INFO_FILE,
                            grpcport=11001,
                            thriftport=10001,
                            pipeconf="org.onosproject.pipelines.p4stm",
                            device_id=1)

        self.addLink(h1, s1, cls=TCLink, bw=10, delay='5ms')
        self.addLink(h2, s1, cls=TCLink, bw=10, delay='5ms')


def run():
    topo = STMTopo()
    net = Mininet(topo=topo, controller=None, autoSetMacs=True)
    net.addController('c0', controller=RemoteController, ip='10.0.1.132', port=6653)

    net.start()
    print("\n--- Running Mininet CLI ---")
    CLI(net)
    net.stop()


if __name__ == '__main__':
    setLogLevel('info')
    run()
