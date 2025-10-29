// Define the headers for Ethernet, IPv4, and UDP (assuming UDP traffic for IoT devices)
header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}


header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header udp_t {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

struct headers {
    ethernet_t   eth;
    ipv4_t       ipv4;
    udp_t        udp;
}


struct metadata {
    // Metadata variables for packet processing
    bit<32> pkt_count;
    bit<32> agg_pkt;        // Aggregated packet payload
    bit<32> disagg_pkt;     // Disaggregated packet payload
    bit<32> disagg_enabled; // Disaggregation status
    bit<32> pkt_threshold;  // Threshold for aggregation
}


// Registers for storing states
register<bit<32>>(pkt_count_reg, 1);
register<bit<32>>(agg_pkt_reg, 1);
register<bit<32>>(disagg_pkt_reg, 1);
register<bit<1>>(disagg_enabled_reg, 1);
register<bit<32>>(pkt_threshold_reg, 1); // Set this based on the aggregation threshold


// Standard control blocks for ingress and egress pipelines
control Ingress(headers hdr, metadata meta, inout standard_metadata_t std_meta) {
    apply {
        // Packet Ingress: Parse Ethernet and IPv4 headers, then proceed to check for disaggregation or aggregation
        if (hdr.ipv4.isValid()) {
            // Check if disaggregation is enabled
            if (disagg_enabled_reg.read(0) == 1) {
                // Disaggregation phase
                meta.pkt_count = pkt_count_reg.read(0);
                meta.disagg_pkt = hdr.udp.length; // Assuming UDP payload as IoT packet content

                // Forward disaggregated packets
                disagg_pkt_reg.write(0, meta.disagg_pkt);
                pkt_count_reg.write(0, 0); // Reset packet count
                disagg_enabled_reg.write(0, 0); // Disable disaggregation for next cycle
            } else {
                // Aggregation phase
                meta.pkt_count = pkt_count_reg.read(0) + 1;
                agg_pkt_reg.write(0, hdr.udp.length); // Accumulate IoT payloads into agg_pkt register

                // Check if packet count reached threshold
                if (meta.pkt_count >= pkt_threshold_reg.read(0)) {
                    // Perform aggregation operations
                    disagg_enabled_reg.write(0, 1); // Enable disaggregation after aggregation
                    pkt_count_reg.write(0, 0); // Reset packet count after aggregation
                } else {
                    pkt_count_reg.write(0, meta.pkt_count); // Update packet count
                }
            }
        } else {
            // Drop packet if headers are invalid
            std_meta.drop = 1;
        }
    }
}


control Egress(headers hdr, metadata meta, inout standard_metadata_t std_meta) {
    apply {
        // Packet Egress: Process and forward the aggregated or disaggregated packet
        // Handle any response packets from server and forward to the next DPADS node
    }
}

control VerifyChecksum(headers hdr, inout metadata meta) {
    apply { }
}

control ComputeChecksum(headers hdr, inout metadata meta) {
    apply { }
}


// Pipeline processing block
control MyIngressPipeline {
    apply {
        VerifyChecksum();
        Ingress();
        ComputeChecksum();
    }
}

control MyEgressPipeline {
    apply {
        Egress();
    }
}

// Main switch pipeline
pipeline main {
    MyIngressPipeline();
    MyEgressPipeline();
}

/* ================= MAIN PACKAGE ================= */

V1Switch(ParserImpl(),
         VerifyChecksumImpl(),
         IngressImpl(),
         EgressImpl(),
         ComputeChecksumImpl(),
         DeparserImpl()) main;
