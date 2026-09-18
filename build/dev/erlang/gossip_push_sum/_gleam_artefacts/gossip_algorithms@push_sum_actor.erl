-module(gossip_algorithms@push_sum_actor).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\gossip_algorithms\\push_sum_actor.gleam").
-export([start_push_sum_actor/3, update_neighbor_subjects/2]).
-export_type([push_sum_message/0, push_sum_state/0]).

-type push_sum_message() :: {push, float(), float()} |
    {update_neighbors,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_message()))} |
    start |
    terminate.

-type push_sum_state() :: {push_sum_state,
        integer(),
        list(integer()),
        float(),
        float(),
        list(float()),
        gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_message())),
        gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())}.

-file("src\\gossip_algorithms\\push_sum_actor.gleam", 125).
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

-file("src\\gossip_algorithms\\push_sum_actor.gleam", 138).
-spec send_to_random_neighbor(push_sum_state(), float(), float()) -> nil.
send_to_random_neighbor(State, S, W) ->
    case erlang:element(3, State) of
        [] ->
            nil;

        Neighbors ->
            Selected_neighbor = case gleam@list:first(Neighbors) of
                {ok, Neighbor_id} ->
                    Neighbor_id;

                {error, _} ->
                    erlang:element(2, State)
            end,
            case gleam_stdlib:map_get(
                erlang:element(7, State),
                Selected_neighbor
            ) of
                {ok, Neighbor_subject} ->
                    gleam@erlang@process:send(Neighbor_subject, {push, S, W});

                {error, _} ->
                    nil
            end
    end.

-file("src\\gossip_algorithms\\push_sum_actor.gleam", 55).
-spec handle_push_sum_message(push_sum_state(), push_sum_message()) -> gleam@otp@actor:next(push_sum_state(), push_sum_message()).
handle_push_sum_message(State, Message) ->
    case Message of
        {push, Received_s, Received_w} ->
            New_s = erlang:element(4, State) + Received_s,
            New_w = erlang:element(5, State) + Received_w,
            Current_ratio = case New_w of
                +0.0 -> +0.0;
                -0.0 -> -0.0;
                Gleam@denominator -> New_s / Gleam@denominator
            end,
            Updated_ratios = begin
                _pipe = [Current_ratio | erlang:element(6, State)],
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
                        erlang:element(8, State),
                        {node_terminated, erlang:element(2, State)}
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Half_s = New_s / 2.0,
                    Half_w = New_w / 2.0,
                    Updated_state = {push_sum_state,
                        erlang:element(2, State),
                        erlang:element(3, State),
                        Half_s,
                        Half_w,
                        Updated_ratios,
                        erlang:element(7, State),
                        erlang:element(8, State)},
                    send_to_random_neighbor(Updated_state, Half_s, Half_w),
                    gleam@otp@actor:continue(Updated_state)
            end;

        start ->
            Half_s@1 = erlang:element(4, State) / 2.0,
            Half_w@1 = erlang:element(5, State) / 2.0,
            Updated_state@1 = {push_sum_state,
                erlang:element(2, State),
                erlang:element(3, State),
                Half_s@1,
                Half_w@1,
                erlang:element(6, State),
                erlang:element(7, State),
                erlang:element(8, State)},
            send_to_random_neighbor(Updated_state@1, Half_s@1, Half_w@1),
            gleam@otp@actor:continue(Updated_state@1);

        {update_neighbors, Neighbor_subjects} ->
            Updated_state@2 = {push_sum_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                erlang:element(6, State),
                Neighbor_subjects,
                erlang:element(8, State)},
            gleam@otp@actor:continue(Updated_state@2);

        terminate ->
            gleam_stdlib:println(
                <<<<"Node "/utf8,
                        (erlang:integer_to_binary(erlang:element(2, State)))/binary>>/binary,
                    " forced termination"/utf8>>
            ),
            gleam@otp@actor:stop()
    end.

-file("src\\gossip_algorithms\\push_sum_actor.gleam", 32).
-spec start_push_sum_actor(
    integer(),
    list(integer()),
    gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(push_sum_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_push_sum_actor(Node_id, Neighbors, Supervisor) ->
    Initial_state = {push_sum_state,
        Node_id,
        Neighbors,
        erlang:float(Node_id),
        1.0,
        [],
        maps:new(),
        Supervisor},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(_pipe, fun handle_push_sum_message/2),
    gleam@otp@actor:start(_pipe@1).

-file("src\\gossip_algorithms\\push_sum_actor.gleam", 163).
-spec update_neighbor_subjects(
    gleam@erlang@process:subject(push_sum_message()),
    gleam@dict:dict(integer(), gleam@erlang@process:subject(push_sum_message()))
) -> nil.
update_neighbor_subjects(Actor_subject, Neighbor_subjects) ->
    gleam@erlang@process:send(
        Actor_subject,
        {update_neighbors, Neighbor_subjects}
    ).
