#include <core.p4>
#include <v1model.p4>

#define CPU_PORT 255

// Define standard headers (Ethernet, IPv4, TCP)
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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
    bit<32> srcAddr;
    bit<32> dstAddr;
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
  ipv4_t ipv4;
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
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp; // TCP
            17: parse_udp; // UDP
            default: accept;
        }
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
        if (hdr.ipv4.isValid() && hdr.tcp.isValid()) {
            state_table.apply();
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
