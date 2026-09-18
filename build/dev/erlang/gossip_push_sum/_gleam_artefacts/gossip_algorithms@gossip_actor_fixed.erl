-module(gossip_algorithms@gossip_actor_fixed).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\gossip_algorithms\\gossip_actor_fixed.gleam").
-export([start_gossip_actor/3, update_neighbor_subjects/2]).
-export_type([gossip_message/0, gossip_state/0]).

-type gossip_message() :: {rumor, binary()} |
    {update_neighbors,
        gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_message()))} |
    terminate.

-type gossip_state() :: {gossip_state,
        integer(),
        list(integer()),
        integer(),
        binary(),
        gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_message())),
        gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())}.

-file("src\\gossip_algorithms\\gossip_actor_fixed.gleam", 92).
-spec forward_rumor_to_random_neighbor(gossip_state()) -> nil.
forward_rumor_to_random_neighbor(State) ->
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
                erlang:element(6, State),
                Selected_neighbor
            ) of
                {ok, Neighbor_subject} ->
                    gleam@erlang@process:send(
                        Neighbor_subject,
                        {rumor, erlang:element(5, State)}
                    );

                {error, _} ->
                    nil
            end
    end.

-file("src\\gossip_algorithms\\gossip_actor_fixed.gleam", 46).
-spec handle_gossip_message(gossip_state(), gossip_message()) -> gleam@otp@actor:next(gossip_state(), gossip_message()).
handle_gossip_message(State, Message) ->
    case Message of
        {rumor, Content} ->
            New_count = erlang:element(4, State) + 1,
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
                    Updated_state = {gossip_state,
                        erlang:element(2, State),
                        erlang:element(3, State),
                        New_count,
                        Content,
                        erlang:element(6, State),
                        erlang:element(7, State)},
                    forward_rumor_to_random_neighbor(Updated_state),
                    gleam@otp@actor:continue(Updated_state)
            end;

        {update_neighbors, Neighbor_subjects} ->
            Updated_state@1 = {gossip_state,
                erlang:element(2, State),
                erlang:element(3, State),
                erlang:element(4, State),
                erlang:element(5, State),
                Neighbor_subjects,
                erlang:element(7, State)},
            gleam@otp@actor:continue(Updated_state@1);

        terminate ->
            gleam_stdlib:println(
                <<<<"Node "/utf8,
                        (erlang:integer_to_binary(erlang:element(2, State)))/binary>>/binary,
                    " forced termination"/utf8>>
            ),
            gleam@otp@actor:stop()
    end.

-file("src\\gossip_algorithms\\gossip_actor_fixed.gleam", 26).
-spec start_gossip_actor(
    integer(),
    list(integer()),
    gleam@erlang@process:subject(gossip_algorithms@types:supervisor_message())
) -> {ok,
        gleam@otp@actor:started(gleam@erlang@process:subject(gossip_message()))} |
    {error, gleam@otp@actor:start_error()}.
start_gossip_actor(Node_id, Neighbors, Supervisor) ->
    Initial_state = {gossip_state,
        Node_id,
        Neighbors,
        0,
        <<""/utf8>>,
        maps:new(),
        Supervisor},
    _pipe = gleam@otp@actor:new(Initial_state),
    _pipe@1 = gleam@otp@actor:on_message(_pipe, fun handle_gossip_message/2),
    gleam@otp@actor:start(_pipe@1).

-file("src\\gossip_algorithms\\gossip_actor_fixed.gleam", 117).
-spec update_neighbor_subjects(
    gleam@erlang@process:subject(gossip_message()),
    gleam@dict:dict(integer(), gleam@erlang@process:subject(gossip_message()))
) -> nil.
update_neighbor_subjects(Actor_subject, Neighbor_subjects) ->
    gleam@erlang@process:send(
        Actor_subject,
        {update_neighbors, Neighbor_subjects}
    ).
