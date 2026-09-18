-module(fault_injector).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\fault_injector.gleam").
-export([kill_random_gossip_node/1, kill_random_push_sum_node/1]).

-file("src\\fault_injector.gleam", 10).
-spec kill_random_gossip_node(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_actor:fault_tolerant_gossip_message()))
) -> nil.
kill_random_gossip_node(Gossip_nodes) ->
    Node_ids = maps:keys(Gossip_nodes),
    case erlang:length(Node_ids) of
        0 ->
            gleam_stdlib:println(
                <<"WARNING: No gossip nodes available to kill"/utf8>>
            ),
            nil;

        Count ->
            Random_seed = (173 * Count) + 1009,
            Target_index = case Count of
                0 -> 0;
                Gleam@denominator -> Random_seed rem Gleam@denominator
            end,
            case begin
                _pipe = gleam@list:drop(Node_ids, Target_index),
                gleam@list:first(_pipe)
            end of
                {ok, Target_node_id} ->
                    case gleam_stdlib:map_get(Gossip_nodes, Target_node_id) of
                        {ok, Target_subject} ->
                            gleam_stdlib:println(<<""/utf8>>),
                            gleam_stdlib:println(
                                <<"FAULT INJECTION: Killing gossip node "/utf8,
                                    (erlang:integer_to_binary(Target_node_id))/binary>>
                            ),
                            gleam@erlang@process:send(Target_subject, terminate),
                            gleam_stdlib:println(
                                <<<<"Node "/utf8,
                                        (erlang:integer_to_binary(
                                            Target_node_id
                                        ))/binary>>/binary,
                                    " has been terminated successfully!"/utf8>>
                            ),
                            gleam_stdlib:println(
                                <<"Other nodes will detect this failure through strike counting mechanism"/utf8>>
                            ),
                            gleam_stdlib:println(<<""/utf8>>);

                        {error, _} ->
                            gleam_stdlib:println(
                                <<"ERROR: Failed to get subject for gossip node "/utf8,
                                    (erlang:integer_to_binary(Target_node_id))/binary>>
                            )
                    end;

                {error, _} ->
                    gleam_stdlib:println(
                        <<"ERROR: Failed to select random gossip node"/utf8>>
                    )
            end
    end.

-file("src\\fault_injector.gleam", 64).
-spec kill_random_push_sum_node(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message()))
) -> nil.
kill_random_push_sum_node(Push_sum_nodes) ->
    Node_ids = maps:keys(Push_sum_nodes),
    case erlang:length(Node_ids) of
        0 ->
            gleam_stdlib:println(
                <<"WARNING: No push-sum nodes available to kill"/utf8>>
            ),
            nil;

        Count ->
            Random_seed = (173 * Count) + 1009,
            Target_index = case Count of
                0 -> 0;
                Gleam@denominator -> Random_seed rem Gleam@denominator
            end,
            case begin
                _pipe = gleam@list:drop(Node_ids, Target_index),
                gleam@list:first(_pipe)
            end of
                {ok, Target_node_id} ->
                    case gleam_stdlib:map_get(Push_sum_nodes, Target_node_id) of
                        {ok, Target_subject} ->
                            gleam_stdlib:println(<<""/utf8>>),
                            gleam_stdlib:println(
                                <<"FAULT INJECTION: Killing push-sum node "/utf8,
                                    (erlang:integer_to_binary(Target_node_id))/binary>>
                            ),
                            gleam@erlang@process:send(Target_subject, terminate),
                            gleam_stdlib:println(
                                <<<<"Node "/utf8,
                                        (erlang:integer_to_binary(
                                            Target_node_id
                                        ))/binary>>/binary,
                                    " has been terminated successfully!"/utf8>>
                            ),
                            gleam_stdlib:println(
                                <<"Other nodes will detect this failure through strike counting mechanism"/utf8>>
                            ),
                            gleam_stdlib:println(<<""/utf8>>);

                        {error, _} ->
                            gleam_stdlib:println(
                                <<"ERROR: Failed to get subject for push-sum node "/utf8,
                                    (erlang:integer_to_binary(Target_node_id))/binary>>
                            )
                    end;

                {error, _} ->
                    gleam_stdlib:println(
                        <<"ERROR: Failed to select random push-sum node"/utf8>>
                    )
            end
    end.
