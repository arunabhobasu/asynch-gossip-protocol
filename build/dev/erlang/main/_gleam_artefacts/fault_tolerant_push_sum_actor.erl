-module(fault_tolerant_push_sum_actor).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\fault_tolerant_push_sum_actor.gleam").
-export([start_fault_tolerant_push_sum_actor/4, update_fault_tolerant_push_sum_neighbor_subjects/2]).
-export_type([fault_tolerant_push_sum_message/0, fault_tolerant_push_sum_state/0]).

-type fault_tolerant_push_sum_message() :: {push, float(), float()} |
    {update_neighbors,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_message()))} |
    {ping, integer()} |
    {pong, integer()} |
    start |
    terminate.

-type fault_tolerant_push_sum_state() :: {fault_tolerant_push_sum_state,
        integer(),
        float(),
        float(),
        list(integer()),
        gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_message())),
        gleam@erlang@process:subject(types:supervisor_message()),
        list(float()),
        integer(),
        gleam@dict:dict(integer(), fault_tolerant_gossip_actor:node_health())}.

-file("src\\fault_tolerant_push_sum_actor.gleam", 159).
-spec check_convergence(list(float())) -> boolean().
check_convergence(Ratios) ->
    case Ratios of
        [R1, R2, R3] ->
            Diff1 = gleam@float:absolute_value(R1 - R2),
            Diff2 = gleam@float:absolute_value(R2 - R3),
            (Diff1 < 0.0000000001) andalso (Diff2 < 0.0000000001);

        _ ->
            false
    end.

-file("src\\fault_tolerant_push_sum_actor.gleam", 222).
-spec get_healthy_neighbors_push_sum(fault_tolerant_push_sum_state()) -> list(integer()).
get_healthy_neighbors_push_sum(State) ->
    gleam@list:filter(
        erlang:element(5, State),
        fun(Neighbor_id) ->
            case gleam_stdlib:map_get(erlang:element(10, State), Neighbor_id) of
                {ok, healthy} ->
                    true;

                {ok, {suspected, _}} ->
                    true;

                {ok, dead} ->
                    false;

                {error, _} ->
                    true
            end
        end
    ).

-file("src\\fault_tolerant_push_sum_actor.gleam", 170).
-spec push_to_healthy_neighbor(
    fault_tolerant_push_sum_state(),
    float(),
    float()
) -> nil.
push_to_healthy_neighbor(State, S, W) ->
    Healthy_neighbors = get_healthy_neighbors_push_sum(State),
    case Healthy_neighbors of
        [] ->
            gleam_stdlib:println(
                <<<<"Node "/utf8,
                        (erlang:integer_to_binary(erlang:element(2, State)))/binary>>/binary,
                    " has no healthy neighbors for push-sum"/utf8>>
            ),
            nil;

        Neighbors ->
            Push_count = erlang:length(erlang:element(8, State)) + 1,
            Random_seed = ((erlang:element(2, State) * 31) + (Push_count * 17))
            + 42,
            Neighbor_index = case erlang:length(Neighbors) of
                0 -> 0;
                Gleam@denominator -> Random_seed rem Gleam@denominator
            end,
            Selected_neighbor = case begin
                _pipe = gleam@list:drop(Neighbors, Neighbor_index),
                gleam@list:first(_pipe)
            end of
                {ok, Neighbor_id} ->
                    Neighbor_id;

                {error, _} ->
                    case gleam@list:first(Neighbors) of
                        {ok, Neighbor_id@1} ->
                            Neighbor_id@1;

                        {error, _} ->
                            erlang:element(2, State)
                    end
            end,
            case gleam_stdlib:map_get(
                erlang:element(6, State),
                Selected_neighbor
            ) of
                {ok, Neighbor_subject} ->
                    gleam@erlang@process:send(Neighbor_subject, {push, S, W}),
                    gleam_stdlib:println(
                        <<<<<<<<<<<<<<<<"Node "/utf8,
                                                        (erlang:integer_to_binary(
                                                            erlang:element(
                                                                2,
                                                                State
                                                            )
                                                        ))/binary>>/binary,
                                                    " pushed to healthy node "/utf8>>/binary,
                                                (erlang:integer_to_binary(
                                                    Selected_neighbor
                                                ))/binary>>/binary,
                                            " (s="/utf8>>/binary,
                                        (gleam_stdlib:float_to_string(S))/binary>>/binary,
                                    ", w="/utf8>>/binary,
                                (gleam_stdlib:float_to_string(W))/binary>>/binary,
                            ")"/utf8>>
                    );

                {error, _} ->
                    nil
            end
    end.

-file("src\\fault_tolerant_push_sum_actor.gleam", 63).
-spec handle_fault_tolerant_push_sum_message(
    fault_tolerant_push_sum_state(),
    fault_tolerant_push_sum_message()
) -> gleam@otp@actor:next(fault_tolerant_push_sum_state(), fault_tolerant_push_sum_message()).
handle_fault_tolerant_push_sum_message(State, Message) ->
    case Message of
        {push, Received_s, Received_w} ->
            New_s = erlang:element(3, State) + Received_s,
            New_w = erlang:element(4, State) + Received_w,
            Current_ratio = case New_w of
                +0.0 -> +0.0;
                -0.0 -> -0.0;
                Gleam@denominator -> New_s / Gleam@denominator
            end,
            Updated_ratios = begin
                _pipe = [Current_ratio | erlang:element(8, State)],
                gleam@list:take(_pipe, 3)
            end,
            case check_convergence(Updated_ratios) of
                true ->
                    gleam_stdlib:println(
                        <<<<<<"Node "/utf8,
                                    (erlang:integer_to_binary(
                                        erlang:element(2, State)
                                    ))/binary>>/binary,
                                " converged with ratio: "/utf8>>/binary,
                            (gleam_stdlib:float_to_string(Current_ratio))/binary>>
                    ),
                    gleam@erlang@process:send(
                        erlang:element(7, State),
                        {node_terminated, erlang:element(2, State)}
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Half_s = New_s / 2.0,
                    Half_w = New_w / 2.0,
                    Updated_state = {fault_tolerant_push_sum_state,
                        erlang:element(2, State),
                        Half_s,
                        Half_w,
                        erlang:element(5, State),
                        erlang:element(6, State),
                        erlang:element(7, State),
                        Updated_ratios,
                        erlang:element(9, State),
                        erlang:element(10, State)},
                    push_to_healthy_neighbor(Updated_state, Half_s, Half_w),
                    gleam@otp@actor:continue(Updated_state)
            end;

        start ->
            Half_s@1 = erlang:element(3, State) / 2.0,
            Half_w@1 = erlang:element(4, State) / 2.0,
            Updated_state@1 = {fault_tolerant_push_sum_state,
                erlang:element(2, State),
                Half_s@1,
                Half_w@1,
                erlang:element(5, State),
                erlang:element(6, State),
                erlang:element(7, State),
                erlang:element(8, State),
                erlang:element(9, State),
                erlang:element(10, State)},
            push_to_healthy_neighbor(Updated_state@1, Half_s@1, Half_w@1),
            gleam@otp@actor:continue(Updated_state@1);

        {ping, From_node_id} ->
            case gleam_stdlib:map_get(erlang:element(6, State), From_node_id) of
                {ok, Neighbor_subject} ->
                    gleam@erlang@process:send(
                        Neighbor_subject,
                        {pong, erlang:element(2, State)}
                    );

                {error, _} ->
                    nil
            end,
            gleam@otp@actor:continue(State);

        {pong, From_node_id@1} ->
            Updated_health = gleam@dict:insert(
                erlang:element(10, State),
                From_node_id@1,
                healthy
            ),
            Updated_state@2 = {fault_tolerant_push_sum_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                erlang:element(6, State),
                erlang:element(7, State),
                erlang:element(8, State),
                erlang:element(9, State),
                Updated_health},
            gleam@otp@actor:continue(Updated_state@2);

        {update_neighbors, Neighbor_subjects} ->
            Initial_health = gleam@list:fold(
                maps:keys(Neighbor_subjects),
                maps:new(),
                fun(Acc, Node_id) ->
                    gleam@dict:insert(Acc, Node_id, healthy)
                end
            ),
            Updated_state@3 = {fault_tolerant_push_sum_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                Neighbor_subjects,
                erlang:element(7, State),
                erlang:element(8, State),
                erlang:element(9, State),
                Initial_health},
            gleam@otp@actor:continue(Updated_state@3);

        terminate ->
            gleam_stdlib:println(
                <<<<"Node "/utf8,
                        (erlang:integer_to_binary(erlang:element(2, State)))/binary>>/binary,
                    " forced termination"/utf8>>
            ),
            gleam@otp@actor:stop()
    end.

-file("src\\fault_tolerant_push_sum_actor.gleam", 36).
-spec start_fault_tolerant_push_sum_actor(
    integer(),
    list(integer()),
    gleam@erlang@process:subject(types:supervisor_message()),
    integer()
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(fault_tolerant_push_sum_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_fault_tolerant_push_sum_actor(Node_id, Neighbors, Supervisor, Max_strikes) ->
    Initial_state = {fault_tolerant_push_sum_state,
        Node_id,
        erlang:float(Node_id),
        1.0,
        Neighbors,
        maps:new(),
        Supervisor,
        [],
        Max_strikes,
        maps:new()},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(
        _pipe,
        fun handle_fault_tolerant_push_sum_message/2
    ),
    gleam@otp@actor:start(_pipe@1).

-file("src\\fault_tolerant_push_sum_actor.gleam", 235).
-spec update_fault_tolerant_push_sum_neighbor_subjects(
    gleam@erlang@process:subject(fault_tolerant_push_sum_message()),
    gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_push_sum_message()))
) -> nil.
update_fault_tolerant_push_sum_neighbor_subjects(
    Actor_subject,
    Neighbor_subjects
) ->
    gleam@erlang@process:send(
        Actor_subject,
        {update_neighbors, Neighbor_subjects}
    ).
