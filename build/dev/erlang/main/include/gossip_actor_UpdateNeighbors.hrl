-record(update_neighbors, {
    neighbors :: gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_actor:gossip_message()))
}).
