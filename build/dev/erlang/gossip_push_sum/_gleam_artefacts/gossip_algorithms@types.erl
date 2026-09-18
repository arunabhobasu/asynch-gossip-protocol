-module(gossip_algorithms@types).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\gossip_algorithms\\types.gleam").
-export_type([supervisor_message/0]).

-type supervisor_message() :: {node_terminated, integer()}.


