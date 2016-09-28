control c(inout bit<16> y) {
    @name("x") bit<32> x;
    @name("arg") bit<32> arg_0;
    @name("a") action a_0() {
        arg_0 = x;
        y = (bit<16>)arg_0;
    }
    action act() {
        x = 32w2;
    }
    table tbl_act() {
        actions = {
            act();
        }
        const default_action = act();
    }
    table tbl_a() {
        actions = {
            a_0();
        }
        const default_action = a_0();
    }
    apply {
        tbl_act.apply();
        tbl_a.apply();
    }
}

control proto(inout bit<16> y);
package top(proto _p);
top(c()) main;
