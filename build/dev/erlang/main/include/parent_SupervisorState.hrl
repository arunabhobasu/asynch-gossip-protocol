-record(supervisor_state, {
    active_nodes :: gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_actor:gossip_message())),
    total_nodes :: integer(),
    start_time :: integer(),
    caller :: gleam@erlang@process:subject(types:convergence_message())
}).
