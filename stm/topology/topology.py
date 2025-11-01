# File: topology/topology.py

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.link import TCLink
from mininet.cli import CLI
from mininet.log import setLogLevel
from p4utils.mininetlib.node import P4Switch

class SimpleP4Switch(P4Switch):
    def __init__(self, name, p4_src, **kwargs):
        super(SimpleP4Switch, self).__init__(name, p4_src="../p4_src/p4_stm.p4", grpc_port=50051, **kwargs)

class STMTopo(Topo):
    def build(self):
        h1 = self.addHost('h1', ip='10.0.1.1/24')
        h2 = self.addHost('h2', ip='10.0.2.2/24')

        # s1 = self.addSwitch('s1', 
        #                    cls=SimpleP4Switch, # Replace with your P4 switch class
        #                    device_id=0,
        #                    p4_src="../p4_src/p4_stm.p4", 
        #                    json_path="../config/p4_stm.json",
        #                    pipeconf="org.onosproject.pipelines.basic",
        #                    thrift_port=9090)

        s1 = self.addSwitch('s1')

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
