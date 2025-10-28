# File: topology/topology.py
"""
Mininet Topology for P4-DPADS Testing
1 switch (s1), 2 hosts (h1, h2), gRPC-based BMv2 switch
"""

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.cli import CLI
from mininet.link import TCLink
import os

class DPADSTopo(Topo):
    def build(self):
        h1 = self.addHost('h1', ip='10.0.1.1/24')
        h2 = self.addHost('h2', ip='10.0.2.2/24')
        s1 = self.addSwitch('s1')

        self.addLink(h1, s1, cls=TCLink, bw=10, delay='5ms')
        self.addLink(h2, s1, cls=TCLink, bw=10, delay='5ms')

if __name__ == '__main__':
    topo = DPADSTopo()
    net = Mininet(topo=topo,
                  link=TCLink,
                  controller=None,
                  autoSetMacs=True,
                  autoStaticArp=True)

    c0 = RemoteController('c0', ip='127.0.0.1', port=6653)
    net.addController(c0)

    net.start()
    print("\n*** Network started. Use pingall or iperf to test connectivity. ***\n")
    CLI(net)
    net.stop()