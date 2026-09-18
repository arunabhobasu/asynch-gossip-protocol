-record(fault_injector_state, {
    active :: boolean(),
    gossip_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_actor:fault_tolerant_gossip_message())),
    push_sum_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message())),
    killed_nodes :: list(integer()),
    kill_delay_ms :: integer(),
    max_kills :: integer()
}).
