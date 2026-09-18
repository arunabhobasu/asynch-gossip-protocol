-record(gossip_state, {
    node_id :: integer(),
    neighbors :: list(integer()),
    rumor_count :: integer(),
    rumor_content :: binary(),
    neighbor_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_actor:gossip_message())),
    supervisor :: gleam@erlang@process:subject(types:supervisor_message())
}).
