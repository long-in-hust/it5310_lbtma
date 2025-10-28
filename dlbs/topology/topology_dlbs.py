from mininet.net import Mininet
from mininet.node import Controller, RemoteController, OVSSwitch, Host
from mininet.link import TCLink
from mininet.cli import CLI

def create_topo():
    net = Mininet(controller=RemoteController, link=TCLink)
    c0 = net.addController('c0', controller=RemoteController, ip='127.0.0.1')
    h1 = net.addHost('h1', ip='10.0.0.1')
    s1 = net.addSwitch('s1')
    h2 = net.addHost('h2', ip='10.0.0.2')
    h3 = net.addHost('h3', ip='10.0.0.3')
    h4 = net.addHost('h4', ip='10.0.0.4')

    net.addLink(h1, s1, bw=10, delay='5ms')
    net.addLink(h2, s1)
    net.addLink(h3, s1)
    net.addLink(h4, s1)

    net.start()
    CLI(net)
    net.stop()

if __name__ == '__main__':
    create_topo()
