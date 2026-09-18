-module(parent).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\parent.gleam").
-export([start_gossip_simulation/3, start_push_sum_simulation/3, start_fault_tolerant_gossip_simulation/4, start_fault_tolerant_push_sum_simulation/4]).
-export_type([supervisor_state/0, push_sum_supervisor_state/0]).

-type supervisor_state() :: {supervisor_state,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_actor:gossip_message())),
        integer(),
        integer(),
        gleam@erlang@process:subject(types:convergence_message())}.

-type push_sum_supervisor_state() :: {push_sum_supervisor_state,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_actor:push_sum_message())),
        integer(),
        integer(),
        gleam@erlang@process:subject(types:convergence_message())}.

-file("src\\parent.gleam", 251).
-spec start_gossip_actors(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:supervisor_message())
) -> gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_actor:gossip_message())).
start_gossip_actors(Num_nodes, Topology_map, Supervisor) ->
    Node_range = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        Node_range,
        maps:new(),
        fun(Acc, Node_id) ->
            Neighbors = case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbor_list} ->
                    Neighbor_list;

                {error, _} ->
                    []
            end,
            case gossip_actor:start_gossip_actor(Node_id, Neighbors, Supervisor) of
                {ok, Started} ->
                    gleam@dict:insert(Acc, Node_id, erlang:element(3, Started));

                {error, _} ->
                    Acc
            end
        end
    ).

-file("src\\parent.gleam", 271).
-spec start_push_sum_actors(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:supervisor_message())
) -> gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_actor:push_sum_message())).
start_push_sum_actors(Num_nodes, Topology_map, Supervisor) ->
    Node_range = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        Node_range,
        maps:new(),
        fun(Acc, Node_id) ->
            Neighbors = case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbor_list} ->
                    Neighbor_list;

                {error, _} ->
                    []
            end,
            case push_sum_actor:start_push_sum_actor(
                Node_id,
                Neighbors,
                Supervisor
            ) of
                {ok, Started} ->
                    gleam@dict:insert(Acc, Node_id, erlang:element(3, Started));

                {error, _} ->
                    Acc
            end
        end
    ).

-file("src\\parent.gleam", 291).
-spec update_gossip_neighbors(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_actor:gossip_message())),
    gleam@dict:dict(integer(), list(integer()))
) -> nil.
update_gossip_neighbors(Node_subjects, Topology_map) ->
    gleam@dict:each(
        Node_subjects,
        fun(Node_id, Subject) ->
            case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbors} ->
                    Neighbor_subjects = gleam@dict:filter(
                        Node_subjects,
                        fun(Neighbor_id, _) ->
                            gleam@list:contains(Neighbors, Neighbor_id)
                        end
                    ),
                    gossip_actor:update_neighbor_subjects(
                        Subject,
                        Neighbor_subjects
                    );

                {error, _} ->
                    nil
            end
        end
    ).

-file("src\\parent.gleam", 309).
-spec update_push_sum_neighbors(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_actor:push_sum_message())),
    gleam@dict:dict(integer(), list(integer()))
) -> nil.
update_push_sum_neighbors(Node_subjects, Topology_map) ->
    gleam@dict:each(
        Node_subjects,
        fun(Node_id, Subject) ->
            case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbors} ->
                    Neighbor_subjects = gleam@dict:filter(
                        Node_subjects,
                        fun(Neighbor_id, _) ->
                            gleam@list:contains(Neighbors, Neighbor_id)
                        end
                    ),
                    push_sum_actor:update_neighbor_subjects(
                        Subject,
                        Neighbor_subjects
                    );

                {error, _} ->
                    nil
            end
        end
    ).

-file("src\\parent.gleam", 332).
-spec get_current_time_millis() -> integer().
get_current_time_millis() ->
    erlang:system_time() div 1000000.

-file("src\\parent.gleam", 146).
-spec handle_gossip_supervisor_message(
    supervisor_state(),
    types:supervisor_message()
) -> gleam@otp@actor:next(supervisor_state(), types:supervisor_message()).
handle_gossip_supervisor_message(State, Message) ->
    case Message of
        {register_nodes, Node_list} ->
            Active_dict = gleam@list:fold(
                Node_list,
                maps:new(),
                fun(Acc, Node_id) ->
                    gleam@dict:insert(
                        Acc,
                        Node_id,
                        gleam@erlang@process:new_subject()
                    )
                end
            ),
            Updated_state = {supervisor_state,
                Active_dict,
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State)},
            gleam@otp@actor:continue(Updated_state);

        {node_terminated, Node_id@1} ->
            Updated_nodes = gleam@dict:delete(
                erlang:element(2, State),
                Node_id@1
            ),
            Remaining_count = maps:size(Updated_nodes),
            gleam_stdlib:println(
                <<<<<<<<"Node "/utf8,
                                (erlang:integer_to_binary(Node_id@1))/binary>>/binary,
                            " terminated. "/utf8>>/binary,
                        (erlang:integer_to_binary(Remaining_count))/binary>>/binary,
                    " nodes remaining."/utf8>>
            ),
            Converged_count = erlang:element(3, State) - Remaining_count,
            Convergence_threshold = 1,
            case Converged_count >= Convergence_threshold of
                true ->
                    End_time = get_current_time_millis(),
                    Duration = End_time - erlang:element(4, State),
                    gleam_stdlib:println(
                        <<<<<<<<"Simulation complete - at least one node reached convergence ("/utf8,
                                        (erlang:integer_to_binary(
                                            Converged_count
                                        ))/binary>>/binary,
                                    "/"/utf8>>/binary,
                                (erlang:integer_to_binary(
                                    erlang:element(3, State)
                                ))/binary>>/binary,
                            " nodes)"/utf8>>
                    ),
                    gleam@erlang@process:send(
                        erlang:element(5, State),
                        {convergence_achieved, Duration}
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Updated_state@1 = {supervisor_state,
                        Updated_nodes,
                        erlang:element(3, State),
                        erlang:element(4, State),
                        erlang:element(5, State)},
                    gleam@otp@actor:continue(Updated_state@1)
            end
    end.

-file("src\\parent.gleam", 112).
-spec start_gossip_supervisor(
    integer(),
    gleam@erlang@process:subject(types:convergence_message())
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(types:supervisor_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_gossip_supervisor(Num_nodes, Caller) ->
    Initial_state = {supervisor_state,
        maps:new(),
        Num_nodes,
        get_current_time_millis(),
        Caller},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(
        _pipe,
        fun handle_gossip_supervisor_message/2
    ),
    gleam@otp@actor:start(_pipe@1).

-file("src\\parent.gleam", 36).
-spec start_gossip_simulation(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:convergence_message())
) -> nil.
start_gossip_simulation(Num_nodes, Topology_map, Caller) ->
    case start_gossip_supervisor(Num_nodes, Caller) of
        {ok, Supervisor_started} ->
            Supervisor_subject = erlang:element(3, Supervisor_started),
            Node_subjects = start_gossip_actors(
                Num_nodes,
                Topology_map,
                Supervisor_subject
            ),
            Node_ids = maps:keys(Node_subjects),
            gleam@erlang@process:send(
                Supervisor_subject,
                {register_nodes, Node_ids}
            ),
            update_gossip_neighbors(Node_subjects, Topology_map),
            case gleam_stdlib:map_get(Node_subjects, 0) of
                {ok, First_node} ->
                    gleam@erlang@process:send(
                        First_node,
                        {rumor, <<"Hello, this is the gossip!"/utf8>>}
                    );

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start gossip simulation - no nodes available"/utf8>>
                    )
            end;

        {error, _} ->
            gleam_stdlib:println(<<"Failed to start gossip supervisor"/utf8>>)
    end.

-file("src\\parent.gleam", 197).
-spec handle_push_sum_supervisor_message(
    push_sum_supervisor_state(),
    types:supervisor_message()
) -> gleam@otp@actor:next(push_sum_supervisor_state(), types:supervisor_message()).
handle_push_sum_supervisor_message(State, Message) ->
    case Message of
        {register_nodes, Node_list} ->
            Active_dict = gleam@list:fold(
                Node_list,
                maps:new(),
                fun(Acc, Node_id) ->
                    gleam@dict:insert(
                        Acc,
                        Node_id,
                        gleam@erlang@process:new_subject()
                    )
                end
            ),
            Updated_state = {push_sum_supervisor_state,
                Active_dict,
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State)},
            gleam@otp@actor:continue(Updated_state);

        {node_terminated, Node_id@1} ->
            Updated_nodes = gleam@dict:delete(
                erlang:element(2, State),
                Node_id@1
            ),
            Remaining_count = maps:size(Updated_nodes),
            Converged_count = erlang:element(3, State) - Remaining_count,
            Convergence_threshold = 1,
            gleam_stdlib:println(
                <<<<<<<<<<<<"Node "/utf8,
                                        (erlang:integer_to_binary(Node_id@1))/binary>>/binary,
                                    " terminated. "/utf8>>/binary,
                                (erlang:integer_to_binary(Converged_count))/binary>>/binary,
                            " nodes converged out of "/utf8>>/binary,
                        (erlang:integer_to_binary(erlang:element(3, State)))/binary>>/binary,
                    " total nodes."/utf8>>
            ),
            case Converged_count >= Convergence_threshold of
                true ->
                    End_time = get_current_time_millis(),
                    Duration = End_time - erlang:element(4, State),
                    gleam_stdlib:println(
                        <<<<<<<<"Simulation complete - at least one node reached convergence! "/utf8,
                                        (erlang:integer_to_binary(
                                            Converged_count
                                        ))/binary>>/binary,
                                    " nodes converged (threshold: "/utf8>>/binary,
                                (erlang:integer_to_binary(Convergence_threshold))/binary>>/binary,
                            ")"/utf8>>
                    ),
                    gleam@erlang@process:send(
                        erlang:element(5, State),
                        {convergence_achieved, Duration}
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Updated_state@1 = {push_sum_supervisor_state,
                        Updated_nodes,
                        erlang:element(3, State),
                        erlang:element(4, State),
                        erlang:element(5, State)},
                    gleam@otp@actor:continue(Updated_state@1)
            end
    end.

-file("src\\parent.gleam", 129).
-spec start_push_sum_supervisor(
    integer(),
    gleam@erlang@process:subject(types:convergence_message())
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(types:supervisor_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_push_sum_supervisor(Num_nodes, Caller) ->
    Initial_state = {push_sum_supervisor_state,
        maps:new(),
        Num_nodes,
        get_current_time_millis(),
        Caller},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(
        _pipe,
        fun handle_push_sum_supervisor_message/2
    ),
    gleam@otp@actor:start(_pipe@1).

-file("src\\parent.gleam", 76).
-spec start_push_sum_simulation(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:convergence_message())
) -> nil.
start_push_sum_simulation(Num_nodes, Topology_map, Caller) ->
    case start_push_sum_supervisor(Num_nodes, Caller) of
        {ok, Supervisor_started} ->
            Supervisor_subject = erlang:element(3, Supervisor_started),
            Node_subjects = start_push_sum_actors(
                Num_nodes,
                Topology_map,
                Supervisor_subject
            ),
            Node_ids = maps:keys(Node_subjects),
            gleam@erlang@process:send(
                Supervisor_subject,
                {register_nodes, Node_ids}
            ),
            update_push_sum_neighbors(Node_subjects, Topology_map),
            case gleam_stdlib:map_get(Node_subjects, 0) of
                {ok, First_node} ->
                    gleam@erlang@process:send(First_node, start);

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start push-sum simulation - no nodes available"/utf8>>
                    )
            end;

        {error, _} ->
            gleam_stdlib:println(<<"Failed to start push-sum supervisor"/utf8>>)
    end.

-file("src\\parent.gleam", 435).
-spec start_fault_tolerant_gossip_actors(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:supervisor_message()),
    integer()
) -> gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_actor:fault_tolerant_gossip_message())).
start_fault_tolerant_gossip_actors(
    Num_nodes,
    Topology_map,
    Supervisor,
    Max_strikes
) ->
    Node_range = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        Node_range,
        maps:new(),
        fun(Acc, Node_id) ->
            Neighbors = case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbor_list} ->
                    Neighbor_list;

                {error, _} ->
                    []
            end,
            case fault_tolerant_gossip_actor:start_fault_tolerant_gossip_actor(
                Node_id,
                Neighbors,
                Supervisor,
                Max_strikes
            ) of
                {ok, Actor_started} ->
                    gleam@dict:insert(
                        Acc,
                        Node_id,
                        erlang:element(3, Actor_started)
                    );

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start fault-tolerant gossip actor "/utf8,
                            (erlang:integer_to_binary(Node_id))/binary>>
                    ),
                    Acc
            end
        end
    ).

-file("src\\parent.gleam", 474).
-spec start_fault_tolerant_push_sum_actors(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:supervisor_message()),
    integer()
) -> gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message())).
start_fault_tolerant_push_sum_actors(
    Num_nodes,
    Topology_map,
    Supervisor,
    Max_strikes
) ->
    Node_range = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        Node_range,
        maps:new(),
        fun(Acc, Node_id) ->
            Neighbors = case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbor_list} ->
                    Neighbor_list;

                {error, _} ->
                    []
            end,
            case fault_tolerant_push_sum_actor:start_fault_tolerant_push_sum_actor(
                Node_id,
                Neighbors,
                Supervisor,
                Max_strikes
            ) of
                {ok, Actor_started} ->
                    gleam@dict:insert(
                        Acc,
                        Node_id,
                        erlang:element(3, Actor_started)
                    );

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start fault-tolerant push-sum actor "/utf8,
                            (erlang:integer_to_binary(Node_id))/binary>>
                    ),
                    Acc
            end
        end
    ).

-file("src\\parent.gleam", 513).
-spec update_fault_tolerant_gossip_neighbors(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_actor:fault_tolerant_gossip_message())),
    gleam@dict:dict(integer(), list(integer()))
) -> nil.
update_fault_tolerant_gossip_neighbors(Node_subjects, Topology_map) ->
    gleam@dict:each(
        Node_subjects,
        fun(Node_id, Node_subject) ->
            Neighbors = case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbor_list} ->
                    Neighbor_list;

                {error, _} ->
                    []
            end,
            Neighbor_subjects = gleam@list:fold(
                Neighbors,
                maps:new(),
                fun(Acc, Neighbor_id) ->
                    case gleam_stdlib:map_get(Node_subjects, Neighbor_id) of
                        {ok, Neighbor_subject} ->
                            gleam@dict:insert(
                                Acc,
                                Neighbor_id,
                                Neighbor_subject
                            );

                        {error, _} ->
                            Acc
                    end
                end
            ),
            fault_tolerant_gossip_actor:update_fault_tolerant_neighbor_subjects(
                Node_subject,
                Neighbor_subjects
            )
        end
    ).

-file("src\\parent.gleam", 338).
-spec start_fault_tolerant_gossip_simulation(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:convergence_message()),
    integer()
) -> nil.
start_fault_tolerant_gossip_simulation(
    Num_nodes,
    Topology_map,
    Caller,
    Max_strikes
) ->
    case start_gossip_supervisor(Num_nodes, Caller) of
        {ok, Supervisor_started} ->
            Supervisor_subject = erlang:element(3, Supervisor_started),
            Node_subjects = start_fault_tolerant_gossip_actors(
                Num_nodes,
                Topology_map,
                Supervisor_subject,
                Max_strikes
            ),
            Node_ids = maps:keys(Node_subjects),
            gleam@erlang@process:send(
                Supervisor_subject,
                {register_nodes, Node_ids}
            ),
            update_fault_tolerant_gossip_neighbors(Node_subjects, Topology_map),
            gleam_stdlib:println(
                <<"FAULT TOLERANCE TESTING: Automatically killing one random node..."/utf8>>
            ),
            fault_injector:kill_random_gossip_node(Node_subjects),
            case gleam_stdlib:map_get(Node_subjects, 0) of
                {ok, First_node} ->
                    gleam@erlang@process:send(
                        First_node,
                        {rumor,
                            <<"Hello, this is the fault-tolerant gossip!"/utf8>>}
                    );

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start fault-tolerant gossip simulation - no nodes available"/utf8>>
                    )
            end;

        {error, _} ->
            gleam_stdlib:println(<<"Failed to start gossip supervisor"/utf8>>)
    end.

-file("src\\parent.gleam", 542).
-spec update_fault_tolerant_push_sum_neighbors(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_actor:fault_tolerant_push_sum_message())),
    gleam@dict:dict(integer(), list(integer()))
) -> nil.
update_fault_tolerant_push_sum_neighbors(Node_subjects, Topology_map) ->
    gleam@dict:each(
        Node_subjects,
        fun(Node_id, Node_subject) ->
            Neighbors = case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Neighbor_list} ->
                    Neighbor_list;

                {error, _} ->
                    []
            end,
            Neighbor_subjects = gleam@list:fold(
                Neighbors,
                maps:new(),
                fun(Acc, Neighbor_id) ->
                    case gleam_stdlib:map_get(Node_subjects, Neighbor_id) of
                        {ok, Neighbor_subject} ->
                            gleam@dict:insert(
                                Acc,
                                Neighbor_id,
                                Neighbor_subject
                            );

                        {error, _} ->
                            Acc
                    end
                end
            ),
            fault_tolerant_push_sum_actor:update_fault_tolerant_push_sum_neighbor_subjects(
                Node_subject,
                Neighbor_subjects
            )
        end
    ).

-file("src\\parent.gleam", 389).
-spec start_fault_tolerant_push_sum_simulation(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(types:convergence_message()),
    integer()
) -> nil.
start_fault_tolerant_push_sum_simulation(
    Num_nodes,
    Topology_map,
    Caller,
    Max_strikes
) ->
    case start_push_sum_supervisor(Num_nodes, Caller) of
        {ok, Supervisor_started} ->
            Supervisor_subject = erlang:element(3, Supervisor_started),
            Node_subjects = start_fault_tolerant_push_sum_actors(
                Num_nodes,
                Topology_map,
                Supervisor_subject,
                Max_strikes
            ),
            Node_ids = maps:keys(Node_subjects),
            gleam@erlang@process:send(
                Supervisor_subject,
                {register_nodes, Node_ids}
            ),
            update_fault_tolerant_push_sum_neighbors(
                Node_subjects,
                Topology_map
            ),
            gleam_stdlib:println(
                <<"FAULT TOLERANCE TESTING: Automatically killing one random node..."/utf8>>
            ),
            fault_injector:kill_random_push_sum_node(Node_subjects),
            case gleam_stdlib:map_get(Node_subjects, 0) of
                {ok, First_node} ->
                    gleam@erlang@process:send(First_node, start);

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start fault-tolerant push-sum simulation - no nodes available"/utf8>>
                    )
            end;

        {error, _} ->
            gleam_stdlib:println(<<"Failed to start push-sum supervisor"/utf8>>)
    end.
