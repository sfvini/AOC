create_clock -name KEY0 -period 50MHz [get_ports {*}]
derive_clock_uncertainty
derive_pll_clocks
