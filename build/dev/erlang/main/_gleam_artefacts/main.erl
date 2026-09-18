-module(main).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\main.gleam").
-export([main/0]).
-export_type([algorithm_type/0]).

-type algorithm_type() :: gossip | push_sum.

-file("src\\main.gleam", 13).
-spec get_args() -> list(binary()).
get_args() ->
    _pipe = init:get_plain_arguments(),
    gleam@list:map(_pipe, fun unicode:characters_to_binary/1).

-file("src\\main.gleam", 107).
-spec parse_topology(binary()) -> {ok, topology:topology_type()} | {error, nil}.
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

-file("src\\main.gleam", 117).
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

-file("src\\main.gleam", 236).
-spec algorithm_to_string(algorithm_type()) -> binary().
algorithm_to_string(Algorithm) ->
    case Algorithm of
        gossip ->
            <<"gossip"/utf8>>;

        push_sum ->
            <<"push-sum"/utf8>>
    end.

-file("src\\main.gleam", 130).
-spec run_simulation(integer(), topology:topology_type(), algorithm_type()) -> nil.
run_simulation(Num_nodes, Topology_type, Algorithm_type) ->
    gleam_stdlib:println(
        <<<<<<<<<<<<"Simulation: "/utf8,
                                (topology:to_string(Topology_type))/binary>>/binary,
                            " topology with "/utf8>>/binary,
                        (erlang:integer_to_binary(Num_nodes))/binary>>/binary,
                    " nodes using "/utf8>>/binary,
                (algorithm_to_string(Algorithm_type))/binary>>/binary,
            " algorithm"/utf8>>
    ),
    Topology_map = topology:build_topology(Num_nodes, Topology_type),
    Convergence_subject = gleam@erlang@process:new_subject(),
    case Algorithm_type of
        gossip ->
            parent:start_gossip_simulation(
                Num_nodes,
                Topology_map,
                Convergence_subject
            );

        push_sum ->
            parent:start_push_sum_simulation(
                Num_nodes,
                Topology_map,
                Convergence_subject
            )
    end,
    case gleam@erlang@process:'receive'(Convergence_subject, 600000) of
        {ok, {convergence_achieved, Duration_ms}} ->
            gleam_stdlib:println(
                <<<<"Convergence time: "/utf8,
                        (erlang:integer_to_binary(Duration_ms))/binary>>/binary,
                    " ms"/utf8>>
            );

        {error, _} ->
            gleam_stdlib:println(
                <<"Simulation timed out after 10 minutes"/utf8>>
            )
    end.

-file("src\\main.gleam", 180).
-spec run_simulation_with_fault_tolerance(
    integer(),
    topology:topology_type(),
    algorithm_type(),
    integer()
) -> nil.
run_simulation_with_fault_tolerance(
    Num_nodes,
    Topology_type,
    Algorithm_type,
    Strike_count
) ->
    gleam_stdlib:println(
        <<<<<<<<<<<<<<<<<<"Fault-Tolerant Simulation: "/utf8,
                                            (topology:to_string(Topology_type))/binary>>/binary,
                                        " topology with "/utf8>>/binary,
                                    (erlang:integer_to_binary(Num_nodes))/binary>>/binary,
                                " nodes using "/utf8>>/binary,
                            (algorithm_to_string(Algorithm_type))/binary>>/binary,
                        " algorithm"/utf8>>/binary,
                    " (Dead node detection: "/utf8>>/binary,
                (erlang:integer_to_binary(Strike_count))/binary>>/binary,
            "-strike rule)"/utf8>>
    ),
    Topology_map = topology:build_topology(Num_nodes, Topology_type),
    Convergence_subject = gleam@erlang@process:new_subject(),
    case Algorithm_type of
        gossip ->
            parent:start_fault_tolerant_gossip_simulation(
                Num_nodes,
                Topology_map,
                Convergence_subject,
                Strike_count
            );

        push_sum ->
            parent:start_fault_tolerant_push_sum_simulation(
                Num_nodes,
                Topology_map,
                Convergence_subject,
                Strike_count
            )
    end,
    case gleam@erlang@process:'receive'(Convergence_subject, 600000) of
        {ok, {convergence_achieved, Duration_ms}} ->
            gleam_stdlib:println(
                <<<<"Convergence time: "/utf8,
                        (erlang:integer_to_binary(Duration_ms))/binary>>/binary,
                    " ms"/utf8>>
            );

        {error, _} ->
            gleam_stdlib:println(
                <<"Simulation timed out after 10 minutes"/utf8>>
            )
    end.

-file("src\\main.gleam", 18).
-spec main() -> nil.
main() ->
    Args = get_args(),
    case Args of
        [Num_nodes_str, Topology_str, Algorithm_str, Strike_count_str] ->
            case gleam_stdlib:parse_int(Num_nodes_str) of
                {ok, Num_nodes} ->
                    case parse_topology(Topology_str) of
                        {ok, Topology_type} ->
                            case parse_algorithm(Algorithm_str) of
                                {ok, Algorithm_type} ->
                                    case gleam_stdlib:parse_int(
                                        Strike_count_str
                                    ) of
                                        {ok, Strike_count} ->
                                            case Strike_count > 0 of
                                                true ->
                                                    run_simulation_with_fault_tolerance(
                                                        Num_nodes,
                                                        Topology_type,
                                                        Algorithm_type,
                                                        Strike_count
                                                    );

                                                false ->
                                                    gleam_stdlib:println(
                                                        <<"Strike count must be a positive integer"/utf8>>
                                                    )
                                            end;

                                        {error, _} ->
                                            gleam_stdlib:println(
                                                <<"Invalid strike count. Must be a positive integer (e.g., 3, 4, 5)"/utf8>>
                                            )
                                    end;

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

        [Num_nodes_str@1, Topology_str@1, Algorithm_str@1] ->
            case gleam_stdlib:parse_int(Num_nodes_str@1) of
                {ok, Num_nodes@1} ->
                    case parse_topology(Topology_str@1) of
                        {ok, Topology_type@1} ->
                            case parse_algorithm(Algorithm_str@1) of
                                {ok, Algorithm_type@1} ->
                                    run_simulation(
                                        Num_nodes@1,
                                        Topology_type@1,
                                        Algorithm_type@1
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
                <<"Usage: project2 numNodes topology algorithm [strikeCount]"/utf8>>
            ),
            gleam_stdlib:println(<<"  numNodes: number of actors"/utf8>>),
            gleam_stdlib:println(<<"  topology: full, 3D, line, imp3D"/utf8>>),
            gleam_stdlib:println(<<"  algorithm: gossip, push-sum"/utf8>>),
            gleam_stdlib:println(
                <<"  strikeCount: (optional) dead node detection strikes (e.g., 3, 4, 5)"/utf8>>
            ),
            gleam_stdlib:println(<<"Examples:"/utf8>>),
            gleam_stdlib:println(
                <<"  gleam run 10 full gossip     # No fault tolerance"/utf8>>
            ),
            gleam_stdlib:println(
                <<"  gleam run 10 full gossip 3   # With 3-strike fault tolerance + automatic node killing"/utf8>>
            )
    end.
