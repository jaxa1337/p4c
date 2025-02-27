#include <core.p4>
#define V1MODEL_VERSION 20200408
#include <v1model.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata {
}

struct headers {
    @name(".data") 
    data_t data;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<data_t>(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    bit<32> key_0;
    @noWarn("unused") @name(".NoAction") action NoAction_0() {
    }
    @name(".setb1") action setb1(@name("val") bit<8> val, @name("port") bit<9> port) {
        hdr.data.b1 = val;
        standard_metadata.egress_spec = port;
    }
    @name(".noop") action noop() {
    }
    @name(".test1") table test1_0 {
        actions = {
            setb1();
            noop();
            @defaultonly NoAction_0();
        }
        key = {
            key_0: exact @name("data.f1") ;
        }
        default_action = NoAction_0();
    }
    @hidden action exact_match_mask1l41() {
        key_0 = hdr.data.f1 & 32w0xff00ff;
    }
    @hidden table tbl_exact_match_mask1l41 {
        actions = {
            exact_match_mask1l41();
        }
        const default_action = exact_match_mask1l41();
    }
    apply {
        tbl_exact_match_mask1l41.apply();
        test1_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<data_t>(hdr.data);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

