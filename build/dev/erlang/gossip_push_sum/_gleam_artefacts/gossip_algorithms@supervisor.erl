-module(gossip_algorithms@supervisor).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\gossip_algorithms\\supervisor.gleam").
-export([start_gossip_simulation/2, start_push_sum_simulation/2]).
-export_type([supervisor_state/0, push_sum_supervisor_state/0]).

-type supervisor_state() :: {supervisor_state,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@gossip_actor_fixed:gossip_message())),
        integer(),
        integer()}.

-type push_sum_supervisor_state() :: {push_sum_supervisor_state,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@push_sum_actor:push_sum_message())),
        integer(),
        integer()}.

-file("src\\gossip_algorithms\\supervisor.gleam", 198).
-spec start_gossip_actors(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())
) -> gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@gossip_actor_fixed:gossip_message())).
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
            case gossip_algorithms@gossip_actor_fixed:start_gossip_actor(
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

-file("src\\gossip_algorithms\\supervisor.gleam", 218).
-spec start_push_sum_actors(
    integer(),
    gleam@dict:dict(integer(), list(integer())),
    gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())
) -> gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@push_sum_actor:push_sum_message())).
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
            case gossip_algorithms@push_sum_actor:start_push_sum_actor(
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

-file("src\\gossip_algorithms\\supervisor.gleam", 238).
-spec update_gossip_neighbors(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@gossip_actor_fixed:gossip_message())),
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
                    gossip_algorithms@gossip_actor_fixed:update_neighbor_subjects(
                        Subject,
                        Neighbor_subjects
                    );

                {error, _} ->
                    nil
            end
        end
    ).

-file("src\\gossip_algorithms\\supervisor.gleam", 256).
-spec update_push_sum_neighbors(
    gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_algorithms@push_sum_actor:push_sum_message())),
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
                    gossip_algorithms@push_sum_actor:update_neighbor_subjects(
                        Subject,
                        Neighbor_subjects
                    );

                {error, _} ->
                    nil
            end
        end
    ).

-file("src\\gossip_algorithms\\supervisor.gleam", 122).
-spec handle_gossip_supervisor_message(
    supervisor_state(),
    gossip_algorithms@types:supervisor_message()
) -> gleam@otp@actor:next(supervisor_state(), gossip_algorithms@types:supervisor_message()).
handle_gossip_supervisor_message(State, Message) ->
    case Message of
        {node_terminated, Node_id} ->
            Updated_nodes = gleam@dict:delete(erlang:element(2, State), Node_id),
            Remaining_count = maps:size(Updated_nodes),
            gleam_stdlib:println(
                <<<<<<<<"Node "/utf8,
                                (erlang:integer_to_binary(Node_id))/binary>>/binary,
                            " terminated. "/utf8>>/binary,
                        (erlang:integer_to_binary(Remaining_count))/binary>>/binary,
                    " nodes remaining."/utf8>>
            ),
            case Remaining_count =:= 0 of
                true ->
                    End_time = erlang:system_time(),
                    Duration = End_time - erlang:element(4, State),
                    gleam_stdlib:println(
                        <<<<"All gossip nodes terminated. Total time: "/utf8,
                                (erlang:integer_to_binary(Duration))/binary>>/binary,
                            " ms"/utf8>>
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Updated_state = {supervisor_state,
                        Updated_nodes,
                        erlang:element(3, State),
                        erlang:element(4, State)},
                    gleam@otp@actor:continue(Updated_state)
            end
    end.

-file("src\\gossip_algorithms\\supervisor.gleam", 92).
-spec start_gossip_supervisor(integer()) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_gossip_supervisor(Num_nodes) ->
    Initial_state = {supervisor_state,
        maps:new(),
        Num_nodes,
        erlang:system_time()},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(
        _pipe,
        fun handle_gossip_supervisor_message/2
    ),
    gleam@otp@actor:start(_pipe@1).

-file("src\\gossip_algorithms\\supervisor.gleam", 28).
-spec start_gossip_simulation(
    integer(),
    gleam@dict:dict(integer(), list(integer()))
) -> nil.
start_gossip_simulation(Num_nodes, Topology_map) ->
    case start_gossip_supervisor(Num_nodes) of
        {ok, Supervisor_started} ->
            Supervisor_subject = erlang:element(3, Supervisor_started),
            Node_subjects = start_gossip_actors(
                Num_nodes,
                Topology_map,
                Supervisor_subject
            ),
            update_gossip_neighbors(Node_subjects, Topology_map),
            case gleam_stdlib:map_get(Node_subjects, 0) of
                {ok, First_node} ->
                    gleam@erlang@process:send(
                        First_node,
                        {rumor, <<"Hello, this is the gossip!"/utf8>>}
                    ),
                    gleam_stdlib:println(<<"Gossip simulation started!"/utf8>>);

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start gossip simulation - no nodes available"/utf8>>
                    )
            end;

        {error, _} ->
            gleam_stdlib:println(<<"Failed to start gossip supervisor"/utf8>>)
    end.

-file("src\\gossip_algorithms\\supervisor.gleam", 160).
-spec handle_push_sum_supervisor_message(
    push_sum_supervisor_state(),
    gossip_algorithms@types:supervisor_message()
) -> gleam@otp@actor:next(push_sum_supervisor_state(), gossip_algorithms@types:supervisor_message()).
handle_push_sum_supervisor_message(State, Message) ->
    case Message of
        {node_terminated, Node_id} ->
            Updated_nodes = gleam@dict:delete(erlang:element(2, State), Node_id),
            Remaining_count = maps:size(Updated_nodes),
            gleam_stdlib:println(
                <<<<<<<<"Node "/utf8,
                                (erlang:integer_to_binary(Node_id))/binary>>/binary,
                            " terminated. "/utf8>>/binary,
                        (erlang:integer_to_binary(Remaining_count))/binary>>/binary,
                    " nodes remaining."/utf8>>
            ),
            case Remaining_count =:= 0 of
                true ->
                    End_time = erlang:system_time(),
                    Duration = End_time - erlang:element(4, State),
                    gleam_stdlib:println(
                        <<<<"All push-sum nodes terminated. Total time: "/utf8,
                                (erlang:integer_to_binary(Duration))/binary>>/binary,
                            " ms"/utf8>>
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Updated_state = {push_sum_supervisor_state,
                        Updated_nodes,
                        erlang:element(3, State),
                        erlang:element(4, State)},
                    gleam@otp@actor:continue(Updated_state)
            end
    end.

-file("src\\gossip_algorithms\\supervisor.gleam", 107).
-spec start_push_sum_supervisor(integer()) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_push_sum_supervisor(Num_nodes) ->
    Initial_state = {push_sum_supervisor_state,
        maps:new(),
        Num_nodes,
        erlang:system_time()},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(
        _pipe,
        fun handle_push_sum_supervisor_message/2
    ),
    gleam@otp@actor:start(_pipe@1).

-file("src\\gossip_algorithms\\supervisor.gleam", 60).
-spec start_push_sum_simulation(
    integer(),
    gleam@dict:dict(integer(), list(integer()))
) -> nil.
start_push_sum_simulation(Num_nodes, Topology_map) ->
    case start_push_sum_supervisor(Num_nodes) of
        {ok, Supervisor_started} ->
            Supervisor_subject = erlang:element(3, Supervisor_started),
            Node_subjects = start_push_sum_actors(
                Num_nodes,
                Topology_map,
                Supervisor_subject
            ),
            update_push_sum_neighbors(Node_subjects, Topology_map),
            case gleam_stdlib:map_get(Node_subjects, 0) of
                {ok, First_node} ->
                    gleam@erlang@process:send(First_node, start),
                    gleam_stdlib:println(
                        <<"Push-sum simulation started!"/utf8>>
                    );

                {error, _} ->
                    gleam_stdlib:println(
                        <<"Failed to start push-sum simulation - no nodes available"/utf8>>
                    )
            end;

        {error, _} ->
            gleam_stdlib:println(<<"Failed to start push-sum supervisor"/utf8>>)
    end.
