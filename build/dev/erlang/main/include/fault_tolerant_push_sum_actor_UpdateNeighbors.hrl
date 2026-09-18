-record(update_neighbors, {
    neighbor_subjects :: gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message()))
}).
