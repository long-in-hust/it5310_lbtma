#include <core.p4>
#include <v1model.p4>

#define CPU_PORT 255

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

// Define standard headers (Ethernet, IPv4, TCP)
header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16> etherType;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  dei;
    bit<12> vid;
    bit<16> nextEtherType; // This holds the *original* EtherType (e.g., 0x0800 for IPv4)
}

header arp_t {
    bit<16> htype;
    bit<16> ptype;
    bit<8>  hlen;
    bit<8>  plen;
    bit<16> opcode;
    bit<48> srcHwAddr;
    bit<32> srcProtAddr;
    bit<48> dstHwAddr;
    bit<32> dstProtAddr;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header ipv6_t {
    bit<4>  version;
    bit<8>  trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLength;
    bit<8>  nextHdr;
    bit<8>  hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header icmp_t {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    bit<32> body; // Covers the 4-byte ID and Sequence Number fields
}


header icmpv6_t {
    bit<8>  type;
    bit<8>  code;
    bit<16> checksum;
    bit<32> body; // Covers the 4-byte ID and Sequence Number fields
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<6>  reserved;
    bit<6>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length;
    bit<16> checksum;
}

@controller_header("packet_in")
header cpu_in_header_t {
    bit<9> ingress_port;
    bit<7> _pad;
}

@controller_header("packet_out")
header cpu_out_header_t {
    bit<9> egress_port;
    bit<7> _pad;
}

struct headers_t {
  ethernet_t ethernet;
  vlan_tag_t vlan;
  arp_t arp;
  ipv4_t ipv4;
  ipv6_t ipv6;
  icmp_t icmp;
  icmpv6_t icmpv6;
  udp_t udp;
  tcp_t tcp;
  cpu_in_header_t cpu_in;
  cpu_out_header_t cpu_out;
} 

struct metadata_t {
    bit<11> flow_id;
    bit<32> packet_size;
    bit<48> timestamp;
}

parser MyParser(packet_in packet,
                out headers_t hdr,
                inout metadata_t meta,
                inout standard_metadata_t standard_meta) {

    state start {
        transition select(standard_meta.ingress_port) {
            CPU_PORT: parse_packet_out;
            default: parse_ethernet;
        }
    }

    state parse_packet_out {
        packet.extract(hdr.cpu_out);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4; // IPv4
            0x8100: parse_vlan; // VLAN (802.1Q)
            0x0806: parse_arp;  // ARP
            0x86dd: parse_ipv6;
            default: accept;
        }
    }

    state parse_vlan {
        // nextEtherType is a field in the vlan_tag_t header you defined above
        packet.extract(hdr.vlan);
        transition select(hdr.vlan.nextEtherType) {
            0x0800: parse_ipv4; // IPv4 *after* VLAN tag
            0x0806: parse_arp;  // ARP *after* VLAN tag
            0x86dd: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            17: parse_udp;
            1: parse_icmp;
            default: accept;
        }
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            6: parse_tcp; // TCP
            17: parse_udp; // UDP
            58: parse_icmpv6;
            default: accept;
        }
    }

    state parse_icmp {
        packet.extract(hdr.icmp);
        transition accept;
    }

    state parse_icmpv6 {
        packet.extract(hdr.icmpv6);
        transition accept;
    }

    state parse_arp {
        packet.extract(hdr.arp);
        transition accept;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
}

control MyVerifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control IngressControl(inout headers_t hdr,
                       inout metadata_t meta,
                       inout standard_metadata_t standard_meta) {
    
    register<bit<16>>(2048) register_flow_count;
    register<bit<48>>(2048) register_last_seen;

    // We use meta.flow_id (calculated in the apply block) as the index.
    action update_state_table() {
        // P4_16 requires .read() and .write() methods
        // 1. Read the current count
        bit<16> current_count;
        register_flow_count.read(current_count, (bit<32>)meta.flow_id);
        // 2. Write the incremented count
        register_flow_count.write((bit<32>)meta.flow_id, current_count + 1);
        // 3. Write the new timestamp
        register_last_seen.write((bit<32>)meta.flow_id, meta.timestamp);
    }

    // Action to create a new entry.
    action create_new_entry() {
        // Set initial count to 1
        register_flow_count.write((bit<32>)meta.flow_id, 1);
        // Set initial timestamp
        register_last_seen.write((bit<32>)meta.flow_id, meta.timestamp);
    }

    @default_only
    table state_table {
        key = {
            hdr.ipv4.srcAddr : exact;
            hdr.ipv4.dstAddr : exact;
            hdr.ipv4.protocol : exact;
            hdr.tcp.srcPort : exact;
            hdr.tcp.dstPort : exact;
        }
        actions = {
            update_state_table;
            create_new_entry;
        }
        size = 1024;
        default_action = create_new_entry;
    }

    // forwarding
    action drop() {
        mark_to_drop(standard_meta);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_meta.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }
    
    apply {
        // Extract flow features (source/destination IP, packet size, etc.)
        meta.packet_size = standard_meta.packet_length;
        meta.timestamp = standard_meta.ingress_global_timestamp;

        if (hdr.cpu_out.isValid()) {
            // Implement logic such that if this is a packet-out from the
            // controller:
            // 1. Set the packet egress port to that found in the cpu_out header
            // 2. Remove (set invalid) the cpu_out header
            // 3. Exit the pipeline here (no need to go through other tables

            standard_meta.egress_spec = hdr.cpu_out.egress_port;
            hdr.cpu_out.setInvalid();
            exit;
        }

        // Perform match-action using the state table
        if (hdr.ipv4.isValid()) {
            if (hdr.tcp.isValid()) {
                state_table.apply();
            }
            ipv4_lpm.apply();
        }
    }
}

control EgressControl(inout headers_t hdr,
                      inout metadata_t meta,
                      inout standard_metadata_t standard_meta) {
    
    apply {
        if (standard_meta.egress_port == CPU_PORT) {
            // *** TODO EXERCISE 4
            // Implement logic such that if the packet is to be forwarded to the
            // CPU port, e.g., if in ingress we matched on the ACL table with
            // action send/clone_to_cpu...
            // 1. Set cpu_in header as valid
            // 2. Set the cpu_in.ingress_port field to the original packet's
            //    ingress port (standard_meta.ingress_port).

            hdr.cpu_in.setValid();
            hdr.cpu_in.ingress_port = standard_meta.ingress_port;
            exit;
        }
    }
}

control MyComputeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply { }
}

control MyDeparser(packet_out packet,
                 in headers_t hdr) {
    apply {
        packet.emit(hdr.cpu_in);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4); 
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
        packet.emit(hdr.icmp);
        packet.emit(hdr.arp);
    }
}

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    IngressControl(),
    EgressControl(),
    MyComputeChecksum(),
    MyDeparser()
) main;
