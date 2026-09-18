-record(start_fault_injection, {
    gossip_nodes :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_actor:fault_tolerant_gossip_message())),
    push_sum_nodes :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message()))
}).
