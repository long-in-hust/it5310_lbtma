/* P4-EWRR Load Balancer */
#include <core.p4>

header ethernet_t {
  bit<48> dstAddr;
  bit<48> srcAddr;
  bit<16> etherType;
}
header ipv4_t {
  bit<4> version;
  bit<4> ihl;
  bit<8> diffserv;
  bit<16> totalLen;
  bit<16> identification;
  bit<3> flags;
  bit<13> fragOffset;
  bit<8> ttl;
  bit<8> protocol;
  bit<16> hdrChecksum;
  bit<32> srcAddr;
  bit<32> dstAddr;
}
header tcp_t {
  bit<16> srcPort;
  bit<16> dstPort;
}

struct headers {
  ethernet_t ethernet;
  ipv4_t ipv4;
  tcp_t tcp;
}

register<bit<8>>(256) Last_Server;
register<bit<8>>(256) Server_State;
register<bit<16>>(256) Server_Res;

control Ingress(inout headers hdr) {
  apply {
    bit<8> idx;
    idx = Last_Server.read(0);
    idx = (idx + 1) % 3;
    Last_Server.write(0, idx);
    if (Server_State.read(idx) == 0) {
      idx = (idx + 1) % 3;
    }
    // rewrite dst IP based on idx
    if (idx == 0) {
      hdr.ipv4.dstAddr = 0x0a000002;
    } else if (idx == 1) {
      hdr.ipv4.dstAddr = 0x0a000003;
    } else {
      hdr.ipv4.dstAddr = 0x0a000004;
    }
  }
}
