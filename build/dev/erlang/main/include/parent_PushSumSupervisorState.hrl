-record(push_sum_supervisor_state, {
    active_nodes :: gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_actor:push_sum_message())),
    total_nodes :: integer(),
    start_time :: integer(),
    caller :: gleam@erlang@process:subject(types:convergence_message())
}).
