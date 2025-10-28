/*
 * dpads.p4 - Complete P4-DPADS: Distributed Packet Aggregation and Disaggregation System
 * Language: P4_16 (BMv2 v1model architecture)
 */

#include <core.p4>

/* ================= HEADER DEFINITIONS ================= */

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

header custom_iot_t {
    bit<8> device_id;
    bit<8> payload_type;
    bit<16> payload_len;
    bit<32> timestamp;
}

/* ================= METADATA & STRUCT DEFINITIONS ================= */

header dpads_meta_t {
    bit<8> agg_id;
    bit<8> pkt_count;
    bit<1> do_disagg;
}

struct metadata {
    dpads_meta_t dpads_meta;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    custom_iot_t custom;
}

/* ================= PARSER ================= */

parser ParserImpl(packet_in packet,
                  out headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            0x0800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition parse_custom;
    }

    state parse_custom {
        packet.extract(hdr.custom);
        transition accept;
    }
}

/* ================= REGISTERS ================= */

register<bit<8>>(1) pkt_count_reg;

/* ================= ACTIONS ================= */

action set_disaggregation() {
    meta.dpads_meta.do_disagg = 1;
}

action reset_packet_count() {
    pkt_count_reg.write(0, 0);
}

action increment_pkt_count() {
    bit<8> count;
    pkt_count_reg.read(count, 0);
    count = count + 1;
    pkt_count_reg.write(0, count);
    meta.dpads_meta.pkt_count = count;

    if (count >= 5) {
        set_disaggregation();
    }
}

action forward(bit<9> port) {
    standard_metadata.egress_spec = port;
}

action drop() {
    mark_to_drop();
}

/* ================= TABLES ================= */

table aggregation_control {
    actions = {
        increment_pkt_count;
        reset_packet_count;
        drop;
    }
    size = 1;
    default_action = increment_pkt_count();
}

table forwarding_table {
    key = {
        hdr.ipv4.dstAddr: exact;
    }
    actions = {
        forward;
        drop;
    }
    size = 1024;
    default_action = drop();
}

/* ================= CONTROL BLOCKS ================= */

control IngressImpl(inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {

    apply {
        aggregation_control.apply();
        forwarding_table.apply();
    }
}

control EgressImpl(inout headers hdr,
                   inout metadata meta,
                   inout standard_metadata_t standard_metadata) {
    apply {
        if (meta.dpads_meta.do_disagg == 1) {
            // Simple disaggregation logic placeholder
            // Disaggregate by replicating payload (real implementation in external logic)
            meta.dpads_meta.do_disagg = 0; // reset flag
        }
    }
}

control VerifyChecksumImpl(inout headers hdr, inout metadata meta) {
    apply { }
}

control ComputeChecksumImpl(inout headers  hdr, inout metadata meta) {
    apply { }
}

control DeparserImpl(packet_out packet,
                     in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.custom);
    }
}

/* ================= MAIN PACKAGE ================= */

V1Switch(ParserImpl(),
         VerifyChecksumImpl(),
         IngressImpl(),
         EgressImpl(),
         ComputeChecksumImpl(),
         DeparserImpl()) main;
