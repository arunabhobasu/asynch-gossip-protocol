-record(gossip_state, {
    node_id :: integer(),
    neighbors :: list(integer()),
    rumor_count :: integer(),
    rumor_content :: binary(),
    neighbor_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@gossip_actor_fixed:gossip_message())),
    supervisor :: gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())
}).
