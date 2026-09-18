-module(fault_tolerant_gossip_actor).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\fault_tolerant_gossip_actor.gleam").
-export([start_fault_tolerant_gossip_actor/4, update_fault_tolerant_neighbor_subjects/2]).
-export_type([fault_tolerant_gossip_message/0, node_health/0, fault_tolerant_gossip_state/0]).

-type fault_tolerant_gossip_message() :: {rumor, binary()} |
    {update_neighbors,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_message()))} |
    {ping, integer()} |
    {pong, integer()} |
    terminate.

-type node_health() :: healthy | {suspected, integer()} | dead.

-type fault_tolerant_gossip_state() :: {fault_tolerant_gossip_state,
        integer(),
        integer(),
        binary(),
        list(integer()),
        gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_message())),
        gleam@erlang@process:subject(types:supervisor_message()),
        integer(),
        gleam@dict:dict(integer(), node_health()),
        gleam@dict:dict(integer(), integer())}.

-file("src\\fault_tolerant_gossip_actor.gleam", 193).
-spec get_healthy_neighbors(fault_tolerant_gossip_state()) -> list(integer()).
get_healthy_neighbors(State) ->
    gleam@list:filter(
        erlang:element(5, State),
        fun(Neighbor_id) ->
            case gleam_stdlib:map_get(erlang:element(9, State), Neighbor_id) of
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

-file("src\\fault_tolerant_gossip_actor.gleam", 148).
-spec forward_rumor_with_fault_tolerance(
    fault_tolerant_gossip_state(),
    binary()
) -> nil.
forward_rumor_with_fault_tolerance(State, Content) ->
    Healthy_neighbors = get_healthy_neighbors(State),
    case Healthy_neighbors of
        [] ->
            gleam_stdlib:println(
                <<<<"Node "/utf8,
                        (erlang:integer_to_binary(erlang:element(2, State)))/binary>>/binary,
                    " has no healthy neighbors to forward rumor to"/utf8>>
            ),
            nil;

        Neighbors ->
            Random_seed = ((erlang:element(2, State) * 127) + (erlang:element(
                3,
                State
            )
            * 73))
            + 1009,
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
                    gleam@erlang@process:send(
                        Neighbor_subject,
                        {rumor, Content}
                    ),
                    gleam_stdlib:println(
                        <<<<<<"Node "/utf8,
                                    (erlang:integer_to_binary(
                                        erlang:element(2, State)
                                    ))/binary>>/binary,
                                " forwarded rumor to healthy node "/utf8>>/binary,
                            (erlang:integer_to_binary(Selected_neighbor))/binary>>
                    );

                {error, _} ->
                    nil
            end
    end.

-file("src\\fault_tolerant_gossip_actor.gleam", 206).
-spec start_periodic_health_check(fault_tolerant_gossip_state()) -> nil.
start_periodic_health_check(State) ->
    gleam@list:each(
        erlang:element(5, State),
        fun(Neighbor_id) ->
            case gleam_stdlib:map_get(erlang:element(6, State), Neighbor_id) of
                {ok, Neighbor_subject} ->
                    gleam@erlang@process:send(
                        Neighbor_subject,
                        {ping, erlang:element(2, State)}
                    );

                {error, _} ->
                    nil
            end
        end
    ).

-file("src\\fault_tolerant_gossip_actor.gleam", 66).
-spec handle_fault_tolerant_gossip_message(
    fault_tolerant_gossip_state(),
    fault_tolerant_gossip_message()
) -> gleam@otp@actor:next(fault_tolerant_gossip_state(), fault_tolerant_gossip_message()).
handle_fault_tolerant_gossip_message(State, Message) ->
    case Message of
        {rumor, Content} ->
            New_count = erlang:element(3, State) + 1,
            forward_rumor_with_fault_tolerance(State, Content),
            case New_count >= 10 of
                true ->
                    gleam_stdlib:println(
                        <<<<<<<<"Node "/utf8,
                                        (erlang:integer_to_binary(
                                            erlang:element(2, State)
                                        ))/binary>>/binary,
                                    " terminating after hearing rumor "/utf8>>/binary,
                                (erlang:integer_to_binary(New_count))/binary>>/binary,
                            " times"/utf8>>
                    ),
                    gleam@erlang@process:send(
                        erlang:element(7, State),
                        {node_terminated, erlang:element(2, State)}
                    ),
                    gleam@otp@actor:stop();

                false ->
                    Updated_state = {fault_tolerant_gossip_state,
                        erlang:element(2, State),
                        New_count,
                        Content,
                        erlang:element(5, State),
                        erlang:element(6, State),
                        erlang:element(7, State),
                        erlang:element(8, State),
                        erlang:element(9, State),
                        erlang:element(10, State)},
                    gleam@otp@actor:continue(Updated_state)
            end;

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
                erlang:element(9, State),
                From_node_id@1,
                healthy
            ),
            Updated_state@1 = {fault_tolerant_gossip_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                erlang:element(6, State),
                erlang:element(7, State),
                erlang:element(8, State),
                Updated_health,
                erlang:element(10, State)},
            gleam@otp@actor:continue(Updated_state@1);

        {update_neighbors, Neighbor_subjects} ->
            Initial_health = gleam@list:fold(
                maps:keys(Neighbor_subjects),
                maps:new(),
                fun(Acc, Node_id) ->
                    gleam@dict:insert(Acc, Node_id, healthy)
                end
            ),
            Updated_state@2 = {fault_tolerant_gossip_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                Neighbor_subjects,
                erlang:element(7, State),
                erlang:element(8, State),
                Initial_health,
                erlang:element(10, State)},
            start_periodic_health_check(Updated_state@2),
            gleam@otp@actor:continue(Updated_state@2);

        terminate ->
            gleam_stdlib:println(
                <<<<"Node "/utf8,
                        (erlang:integer_to_binary(erlang:element(2, State)))/binary>>/binary,
                    " forced termination"/utf8>>
            ),
            gleam@otp@actor:stop()
    end.

-file("src\\fault_tolerant_gossip_actor.gleam", 39).
-spec start_fault_tolerant_gossip_actor(
    integer(),
    list(integer()),
    gleam@erlang@process:subject(types:supervisor_message()),
    integer()
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(fault_tolerant_gossip_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_fault_tolerant_gossip_actor(Node_id, Neighbors, Supervisor, Max_strikes) ->
    Initial_state = {fault_tolerant_gossip_state,
        Node_id,
        0,
        <<""/utf8>>,
        Neighbors,
        maps:new(),
        Supervisor,
        Max_strikes,
        maps:new(),
        maps:new()},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(
        _pipe,
        fun handle_fault_tolerant_gossip_message/2
    ),
    gleam@otp@actor:start(_pipe@1).

-file("src\\fault_tolerant_gossip_actor.gleam", 218).
-spec update_fault_tolerant_neighbor_subjects(
    gleam@erlang@process:subject(fault_tolerant_gossip_message()),
    gleam@dict:dict(integer(), gleam@erlang@process:subject(fault_tolerant_gossip_message()))
) -> nil.
update_fault_tolerant_neighbor_subjects(Actor_subject, Neighbor_subjects) ->
    gleam@erlang@process:send(
        Actor_subject,
        {update_neighbors, Neighbor_subjects}
    ).
