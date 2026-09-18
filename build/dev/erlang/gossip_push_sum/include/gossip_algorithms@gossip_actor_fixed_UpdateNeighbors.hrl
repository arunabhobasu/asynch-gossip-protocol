-record(update_neighbors, {
    neighbors :: gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@gossip_actor_fixed:gossip_message()))
}).
