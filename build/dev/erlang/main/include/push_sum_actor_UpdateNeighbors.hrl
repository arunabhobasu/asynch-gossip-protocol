-record(update_neighbors, {
    neighbors :: gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_actor:push_sum_message()))
}).
