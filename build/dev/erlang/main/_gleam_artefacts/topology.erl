-module(topology).
-compile([no_auto_import, nowarn_unused_vars, nowarn_unused_function, nowarn_nomatch, inline]).
-define(FILEPATH, "src\\topology.gleam").
-export([to_string/1, build_topology/2]).
-export_type([topology_type/0]).

-type topology_type() :: full | grid3_d | line | imperfect_grid3_d.

-file("src\\topology.gleam", 15).
-spec to_string(topology_type()) -> binary().
to_string(Topology) ->
    case Topology of
        full ->
            <<"Full Network"/utf8>>;

        grid3_d ->
            <<"3D Grid"/utf8>>;

        line ->
            <<"Line"/utf8>>;

        imperfect_grid3_d ->
            <<"Imperfect 3D Grid"/utf8>>
    end.

-file("src\\topology.gleam", 36).
-spec build_full_topology(integer()) -> gleam@dict:dict(integer(), list(integer())).
build_full_topology(Num_nodes) ->
    All_nodes = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        All_nodes,
        maps:new(),
        fun(Topology_map, Node_id) ->
            Neighbors = gleam@list:filter(
                All_nodes,
                fun(Other_id) -> Other_id /= Node_id end
            ),
            gleam@dict:insert(Topology_map, Node_id, Neighbors)
        end
    ).

-file("src\\topology.gleam", 54).
-spec get_line_neighbors(integer(), integer()) -> list(integer()).
get_line_neighbors(Node_id, Num_nodes) ->
    case Node_id of
        0 ->
            [1];

        Id when Id =:= (Num_nodes - 1) ->
            [Num_nodes - 2];

        Id@1 ->
            [Id@1 - 1, Id@1 + 1]
    end.

-file("src\\topology.gleam", 45).
-spec build_line_topology(integer()) -> gleam@dict:dict(integer(), list(integer())).
build_line_topology(Num_nodes) ->
    All_nodes = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        All_nodes,
        maps:new(),
        fun(Topology_map, Node_id) ->
            Neighbors = get_line_neighbors(Node_id, Num_nodes),
            gleam@dict:insert(Topology_map, Node_id, Neighbors)
        end
    ).

-file("src\\topology.gleam", 76).
-spec find_cube_root(integer(), integer()) -> integer().
find_cube_root(Target, Current) ->
    case ((Current * Current) * Current) >= Target of
        true ->
            Current;

        false ->
            find_cube_root(Target, Current + 1)
    end.

-file("src\\topology.gleam", 72).
-spec calculate_cube_size(integer()) -> integer().
calculate_cube_size(Num_nodes) ->
    find_cube_root(Num_nodes, 1).

-file("src\\topology.gleam", 103).
-spec node_id_to_3d_coords(integer(), integer()) -> {integer(),
    integer(),
    integer()}.
node_id_to_3d_coords(Node_id, Cube_size) ->
    Plane_size = Cube_size * Cube_size,
    Z = case Plane_size of
        0 -> 0;
        Gleam@denominator -> Node_id div Gleam@denominator
    end,
    Remaining = case Plane_size of
        0 -> 0;
        Gleam@denominator@1 -> Node_id rem Gleam@denominator@1
    end,
    Y = case Cube_size of
        0 -> 0;
        Gleam@denominator@2 -> Remaining div Gleam@denominator@2
    end,
    X = case Cube_size of
        0 -> 0;
        Gleam@denominator@3 -> Remaining rem Gleam@denominator@3
    end,
    {X, Y, Z}.

-file("src\\topology.gleam", 112).
-spec coords_3d_to_node_id({integer(), integer(), integer()}, integer()) -> integer().
coords_3d_to_node_id(Coords, Cube_size) ->
    {X, Y, Z} = Coords,
    (((Z * Cube_size) * Cube_size) + (Y * Cube_size)) + X.

-file("src\\topology.gleam", 117).
-spec is_valid_3d_coords({integer(), integer(), integer()}, integer()) -> boolean().
is_valid_3d_coords(Coords, Cube_size) ->
    {X, Y, Z} = Coords,
    (((((X >= 0) andalso (X < Cube_size)) andalso (Y >= 0)) andalso (Y < Cube_size))
    andalso (Z >= 0))
    andalso (Z < Cube_size).

-file("src\\topology.gleam", 83).
-spec get_3d_grid_neighbors(integer(), integer(), integer()) -> list(integer()).
get_3d_grid_neighbors(Node_id, Cube_size, Num_nodes) ->
    {X, Y, Z} = node_id_to_3d_coords(Node_id, Cube_size),
    _pipe = [{X - 1, Y, Z},
        {X + 1, Y, Z},
        {X, Y - 1, Z},
        {X, Y + 1, Z},
        {X, Y, Z - 1},
        {X, Y, Z + 1}],
    _pipe@1 = gleam@list:filter(
        _pipe,
        fun(Coords) -> is_valid_3d_coords(Coords, Cube_size) end
    ),
    _pipe@2 = gleam@list:map(
        _pipe@1,
        fun(Coords@1) -> coords_3d_to_node_id(Coords@1, Cube_size) end
    ),
    gleam@list:filter(_pipe@2, fun(Neighbor_id) -> Neighbor_id < Num_nodes end).

-file("src\\topology.gleam", 62).
-spec build_3d_grid_topology(integer()) -> gleam@dict:dict(integer(), list(integer())).
build_3d_grid_topology(Num_nodes) ->
    Cube_size = calculate_cube_size(Num_nodes),
    All_nodes = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        All_nodes,
        maps:new(),
        fun(Topology_map, Node_id) ->
            Neighbors = get_3d_grid_neighbors(Node_id, Cube_size, Num_nodes),
            gleam@dict:insert(Topology_map, Node_id, Neighbors)
        end
    ).

-file("src\\topology.gleam", 139).
-spec get_random_neighbor(integer(), list(integer()), integer()) -> integer().
get_random_neighbor(Node_id, Current_neighbors, Num_nodes) ->
    Excluded_set = gleam@set:from_list([Node_id | Current_neighbors]),
    All_nodes = gleam@list:range(0, Num_nodes - 1),
    Available_neighbors = gleam@list:filter(
        All_nodes,
        fun(Id) -> not gleam@set:contains(Excluded_set, Id) end
    ),
    case Available_neighbors of
        [] ->
            Node_id;

        Neighbors ->
            Random_seed = ((Node_id * 31) + (Num_nodes * 17)) + 42,
            Neighbor_index = case erlang:length(Neighbors) of
                0 -> 0;
                Gleam@denominator -> Random_seed rem Gleam@denominator
            end,
            case begin
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
                            Node_id
                    end
            end
    end.

-file("src\\topology.gleam", 122).
-spec build_imperfect_3d_grid_topology(integer()) -> gleam@dict:dict(integer(), list(integer())).
build_imperfect_3d_grid_topology(Num_nodes) ->
    Base_topology = build_3d_grid_topology(Num_nodes),
    All_nodes = gleam@list:range(0, Num_nodes - 1),
    gleam@list:fold(
        All_nodes,
        Base_topology,
        fun(Topology_map, Node_id) ->
            case gleam_stdlib:map_get(Topology_map, Node_id) of
                {ok, Current_neighbors} ->
                    Random_neighbor = get_random_neighbor(
                        Node_id,
                        Current_neighbors,
                        Num_nodes
                    ),
                    Updated_neighbors = [Random_neighbor | Current_neighbors],
                    gleam@dict:insert(Topology_map, Node_id, Updated_neighbors);

                {error, _} ->
                    Topology_map
            end
        end
    ).

-file("src\\topology.gleam", 24).
-spec build_topology(integer(), topology_type()) -> gleam@dict:dict(integer(), list(integer())).
build_topology(Num_nodes, Topology_type) ->
    case Topology_type of
        full ->
            build_full_topology(Num_nodes);

        grid3_d ->
            build_3d_grid_topology(Num_nodes);

        line ->
            build_line_topology(Num_nodes);

        imperfect_grid3_d ->
            build_imperfect_3d_grid_topology(Num_nodes)
    end.
