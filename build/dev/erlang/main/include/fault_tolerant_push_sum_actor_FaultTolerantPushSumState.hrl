-record(fault_tolerant_push_sum_state, {
    node_id :: integer(),
    s :: float(),
    w :: float(),
    neighbors :: list(integer()),
    neighbor_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message())),
    supervisor :: gleam@erlang@process:subject(types:supervisor_message()),
    previous_ratios :: list(float()),
    max_strikes :: integer(),
    node_health :: gleam@dict:dict(integer(), fault_tolerant_gossip_actor:node_health())
}).
