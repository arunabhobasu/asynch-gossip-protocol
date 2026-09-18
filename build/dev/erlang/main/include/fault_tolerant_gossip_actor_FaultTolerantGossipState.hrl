-record(fault_tolerant_gossip_state, {
    node_id :: integer(),
    rumor_count :: integer(),
    rumor_content :: binary(),
    neighbors :: list(integer()),
    neighbor_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_actor:fault_tolerant_gossip_message())),
    supervisor :: gleam@erlang@process:subject(types:supervisor_message()),
    max_strikes :: integer(),
    node_health :: gleam@dict:dict(integer(), fault_tolerant_gossip_actor:node_health()),
    last_ping_time :: gleam@dict:dict(integer(), integer())
}).
