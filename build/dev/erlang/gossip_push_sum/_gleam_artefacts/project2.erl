-module(project2).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\project2.gleam").
-export([main/0]).
-export_type([algorithm_type/0]).

-type algorithm_type() :: gossip | push_sum.

-file("src\\project2.gleam", 45).
-spec parse_topology(binary()) -> {ok,
        gossip_algorithms@topology:topology_type()} |
    {error, nil}.
parse_topology(Topology_str) ->
    case Topology_str of
        <<"full"/utf8>> ->
            {ok, full};

        <<"3D"/utf8>> ->
            {ok, grid3_d};

        <<"line"/utf8>> ->
            {ok, line};

        <<"imp3D"/utf8>> ->
            {ok, imperfect_grid3_d};

        _ ->
            {error, nil}
    end.

-file("src\\project2.gleam", 55).
-spec parse_algorithm(binary()) -> {ok, algorithm_type()} | {error, nil}.
parse_algorithm(Algorithm_str) ->
    case Algorithm_str of
        <<"gossip"/utf8>> ->
            {ok, gossip};

        <<"push-sum"/utf8>> ->
            {ok, push_sum};

        _ ->
            {error, nil}
    end.

-file("src\\project2.gleam", 103).
-spec algorithm_to_string(algorithm_type()) -> binary().
algorithm_to_string(Algorithm) ->
    case Algorithm of
        gossip ->
            <<"gossip"/utf8>>;

        push_sum ->
            <<"push-sum"/utf8>>
    end.

-file("src\\project2.gleam", 68).
-spec run_simulation(
    integer(),
    gossip_algorithms@topology:topology_type(),
    algorithm_type()
) -> nil.
run_simulation(Num_nodes, Topology_type, Algorithm_type) ->
    gleam_stdlib:println(
        <<<<"Starting simulation with "/utf8,
                (erlang:integer_to_binary(Num_nodes))/binary>>/binary,
            " nodes"/utf8>>
    ),
    gleam_stdlib:println(
        <<"Topology: "/utf8,
            (gossip_algorithms@topology:to_string(Topology_type))/binary>>
    ),
    gleam_stdlib:println(
        <<"Algorithm: "/utf8, (algorithm_to_string(Algorithm_type))/binary>>
    ),
    Topology_map = gossip_algorithms@topology:build_topology(
        Num_nodes,
        Topology_type
    ),
    Start_time = erlang:system_time(),
    case Algorithm_type of
        gossip ->
            gossip_algorithms@supervisor:start_gossip_simulation(
                Num_nodes,
                Topology_map
            );

        push_sum ->
            gossip_algorithms@supervisor:start_push_sum_simulation(
                Num_nodes,
                Topology_map
            )
    end,
    End_time = erlang:system_time(),
    gleam_stdlib:println(
        <<<<"Convergence time: "/utf8,
                (erlang:integer_to_binary(End_time - Start_time))/binary>>/binary,
            " ms"/utf8>>
    ).

-file("src\\project2.gleam", 9).
-spec main() -> nil.
main() ->
    Args = init:get_plain_arguments(),
    case Args of
        [Num_nodes_str, Topology_str, Algorithm_str] ->
            case gleam_stdlib:parse_int(Num_nodes_str) of
                {ok, Num_nodes} ->
                    case parse_topology(Topology_str) of
                        {ok, Topology_type} ->
                            case parse_algorithm(Algorithm_str) of
                                {ok, Algorithm_type} ->
                                    run_simulation(
                                        Num_nodes,
                                        Topology_type,
                                        Algorithm_type
                                    );

                                {error, _} ->
                                    gleam_stdlib:println(
                                        <<"Invalid algorithm. Use: gossip, push-sum"/utf8>>
                                    )
                            end;

                        {error, _} ->
                            gleam_stdlib:println(
                                <<"Invalid topology. Use: full, 3D, line, imp3D"/utf8>>
                            )
                    end;

                {error, _} ->
                    gleam_stdlib:println(<<"Invalid number of nodes"/utf8>>)
            end;

        _ ->
            gleam_stdlib:println(
                <<"Usage: project2 numNodes topology algorithm"/utf8>>
            ),
            gleam_stdlib:println(<<"  numNodes: number of actors"/utf8>>),
            gleam_stdlib:println(<<"  topology: full, 3D, line, imp3D"/utf8>>),
            gleam_stdlib:println(<<"  algorithm: gossip, push-sum"/utf8>>)
    end.
