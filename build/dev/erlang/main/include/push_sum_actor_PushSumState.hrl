-record(push_sum_state, {
    node_id :: integer(),
    neighbors :: list(integer()),
    s :: float(),
    w :: float(),
    previous_ratios :: list(float()),
    neighbor_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_actor:push_sum_message())),
    supervisor :: gleam@erlang@process:subject(types:supervisor_message())
}).
