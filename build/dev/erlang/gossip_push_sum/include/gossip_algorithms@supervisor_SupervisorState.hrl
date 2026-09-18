-record(supervisor_state, {
    active_nodes :: gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@gossip_actor_fixed:gossip_message())),
    total_nodes :: integer(),
    start_time :: integer()
}).
