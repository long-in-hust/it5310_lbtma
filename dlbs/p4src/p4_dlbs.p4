/* 
P4-DLBS Module: Distributed Load Balancing with Enhanced Weighted Round Robin (P4-EWRR)
*/

/* Define headers */
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
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<6> reserved;
    bit<6> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

/* Metadata and global variables */
struct metadata_t {
    bit<32> server_index;
    bit<32> total_weight;
    bit<32> cum_weight;
    bit<32> rand_value;
    bit<32> remaining_resources;
}

metadata_t meta;

/* Registers */
register<bit<32>>(1) Last_Server;  // Store the index of last serving server
register<bit<32>>(1) Selected_Index;  // Store the selected server index
register<bit<32>>(10) Server_Res;  // Store remaining resources for each server
register<bit<32>>(10) Server_State;  // Store health state of servers (0: down, 1: up)

/* Parser */
parser MyParser(packet_in pkt, out headers_t hdr, inout metadata_t meta) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }
    
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            6: parse_tcp;
            default: accept;
        }
    }
    
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}

/* Ingress Pipeline */
action round_robin_selection() {
    bit<32> n = 10;  // Assuming 10 servers
    bit<32> server_index = Last_Server.read(0);
    
    // Enhanced Weighted Round Robin (EWRR)
    meta.total_weight = 0;
    for (bit<32> i = 0; i < n; i++) {
        bit<32> weight = Server_Res.read(i);
        meta.total_weight += weight;
    }
    
    // Random selection based on weight
    meta.rand_value = random(meta.total_weight);  // Generate a random value
    meta.cum_weight = 0;

    for (bit<32> i = 0; i < n; i++) {
        bit<32> cur_weight = Server_Res.read(i);
        meta.cum_weight += cur_weight;
        if (meta.rand_value < meta.cum_weight) {
            server_index = i;
            break;
        }
    }

    // Health check: ensure the selected server is up
    if (Server_State.read(server_index) == 0) {
        server_index = (server_index + 1) % n;  // Round-robin to next server if down
    }

    // Update selected server index and last server
    Selected_Index.write(0, server_index);
    Last_Server.write(0, server_index);
}

action forward_to_server(bit<32> server_index) {
    // Modify packet headers to forward to the selected server
    modify_field(hdr.ethernet.dstAddr, server_mac[server_index]);
    modify_field(hdr.ipv4.dstAddr, server_ip[server_index]);
    modify_field(hdr.tcp.dstPort, server_port[server_index]);
    
    // Send to the corresponding port
    standard_metadata.egress_spec = server_port[server_index];
}

table load_balancing_table {
    actions = {
        round_robin_selection;
        forward_to_server;
    }
    key = {
        hdr.ipv4.srcAddr: ternary;
        hdr.ipv4.dstAddr: ternary;
    }
    size = 1024;
    default_action = round_robin_selection;
}

control ingress {
    apply(load_balancing_table);
}

/* Egress Pipeline */
control egress {
    // Optional egress processing (e.g., for server responses)
}

/* Deparser */
control MyDeparser(packet_out pkt, in headers_t hdr) {
    pkt.emit(hdr.ethernet);
    pkt.emit(hdr.ipv4);
    pkt.emit(hdr.tcp);
}

/* Main Control Block */
control MyControl(
    inout headers_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t standard_metadata
) {
    apply {
        ingress.apply();
        egress.apply();
    }
}

/* Switch Program */
V1Switch(MyParser(), MyDeparser(), MyControl()) {
}
