#include <core.p4>
#include <ebpf_model.p4>

@ethernetaddress typedef bit<48> EthernetAddress;
@ipv4address typedef bit<32> IPv4Address;
header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

header IPv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    IPv4Address srcAddr;
    IPv4Address dstAddr;
}

struct Headers_t {
    Ethernet_h ethernet;
    IPv4_h[2]  ipv4;
}

parser prs(packet_in p, out Headers_t headers) {
    state start {
        p.extract<Ethernet_h>(headers.ethernet);
        transition select(headers.ethernet.etherType) {
            16w0x800: ip;
            default: reject;
        }
    }
    state ip {
        p.extract<IPv4_h>(headers.ipv4[0]);
        p.extract<IPv4_h>(headers.ipv4[1]);
        transition accept;
    }
}

control pipe(inout Headers_t headers, out bool pass) {
    @noWarn("unused") @name(".NoAction") action NoAction_0() {
    }
    @name("pipe.Reject") action Reject(@name("add") IPv4Address add_1) {
        pass = false;
        headers.ipv4[0].srcAddr = add_1;
    }
    @name("pipe.Check_src_ip") table Check_src_ip_0 {
        key = {
            headers.ipv4[0].srcAddr: exact @name("headers.ipv4[0].srcAddr") ;
        }
        actions = {
            Reject();
            NoAction_0();
        }
        implementation = hash_table(32w1024);
        const default_action = NoAction_0();
    }
    @hidden action stack_ebpf73() {
        pass = false;
    }
    @hidden action stack_ebpf69() {
        pass = true;
    }
    @hidden table tbl_stack_ebpf69 {
        actions = {
            stack_ebpf69();
        }
        const default_action = stack_ebpf69();
    }
    @hidden table tbl_stack_ebpf73 {
        actions = {
            stack_ebpf73();
        }
        const default_action = stack_ebpf73();
    }
    apply {
        tbl_stack_ebpf69.apply();
        switch (Check_src_ip_0.apply().action_run) {
            Reject: {
                tbl_stack_ebpf73.apply();
            }
            NoAction_0: {
            }
        }
    }
}

ebpfFilter<Headers_t>(prs(), pipe()) main;

