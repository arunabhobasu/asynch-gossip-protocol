import gleam/dict.{type Dict}
import gleam/list
import gleam/set

pub type TopologyType {
  Full
  Grid3D
  Line
  ImperfectGrid3D
}

pub type TopologyMap =
  Dict(Int, List(Int))

pub fn to_string(topology: TopologyType) -> String {
  case topology {
    Full -> "Full Network"
    Grid3D -> "3D Grid"
    Line -> "Line"
    ImperfectGrid3D -> "Imperfect 3D Grid"
  }
}

pub fn build_topology(
  num_nodes: Int,
  topology_type: TopologyType,
) -> TopologyMap {
  case topology_type {
    Full -> build_full_topology(num_nodes)
    Grid3D -> build_3d_grid_topology(num_nodes)
    Line -> build_line_topology(num_nodes)
    ImperfectGrid3D -> build_imperfect_3d_grid_topology(num_nodes)
  }
}

fn build_full_topology(num_nodes: Int) -> TopologyMap {
  let all_nodes = list.range(0, num_nodes - 1)

  list.fold(all_nodes, dict.new(), fn(topology_map, node_id) {
    let neighbors = list.filter(all_nodes, fn(other_id) { other_id != node_id })
    dict.insert(topology_map, node_id, neighbors)
  })
}

fn build_line_topology(num_nodes: Int) -> TopologyMap {
  let all_nodes = list.range(0, num_nodes - 1)

  list.fold(all_nodes, dict.new(), fn(topology_map, node_id) {
    let neighbors = get_line_neighbors(node_id, num_nodes)
    dict.insert(topology_map, node_id, neighbors)
  })
}

fn get_line_neighbors(node_id: Int, num_nodes: Int) -> List(Int) {
  case node_id {
    0 -> [1]
    id if id == num_nodes - 1 -> [num_nodes - 2]
    id -> [id - 1, id + 1]
  }
}

fn build_3d_grid_topology(num_nodes: Int) -> TopologyMap {
  let cube_size = calculate_cube_size(num_nodes)
  let all_nodes = list.range(0, num_nodes - 1)

  list.fold(all_nodes, dict.new(), fn(topology_map, node_id) {
    let neighbors = get_3d_grid_neighbors(node_id, cube_size, num_nodes)
    dict.insert(topology_map, node_id, neighbors)
  })
}

fn calculate_cube_size(num_nodes: Int) -> Int {
  find_cube_root(num_nodes, 1)
}

fn find_cube_root(target: Int, current: Int) -> Int {
  case current * current * current >= target {
    True -> current
    False -> find_cube_root(target, current + 1)
  }
}

fn get_3d_grid_neighbors(
  node_id: Int,
  cube_size: Int,
  num_nodes: Int,
) -> List(Int) {
  let #(x, y, z) = node_id_to_3d_coords(node_id, cube_size)

  [
    #(x - 1, y, z),
    #(x + 1, y, z),
    #(x, y - 1, z),
    #(x, y + 1, z),
    #(x, y, z - 1),
    #(x, y, z + 1),
  ]
  |> list.filter(fn(coords) { is_valid_3d_coords(coords, cube_size) })
  |> list.map(fn(coords) { coords_3d_to_node_id(coords, cube_size) })
  |> list.filter(fn(neighbor_id) { neighbor_id < num_nodes })
}

fn node_id_to_3d_coords(node_id: Int, cube_size: Int) -> #(Int, Int, Int) {
  let plane_size = cube_size * cube_size
  let z = node_id / plane_size
  let remaining = node_id % plane_size
  let y = remaining / cube_size
  let x = remaining % cube_size
  #(x, y, z)
}

fn coords_3d_to_node_id(coords: #(Int, Int, Int), cube_size: Int) -> Int {
  let #(x, y, z) = coords
  z * cube_size * cube_size + y * cube_size + x
}

fn is_valid_3d_coords(coords: #(Int, Int, Int), cube_size: Int) -> Bool {
  let #(x, y, z) = coords
  x >= 0 && x < cube_size && y >= 0 && y < cube_size && z >= 0 && z < cube_size
}

fn build_imperfect_3d_grid_topology(num_nodes: Int) -> TopologyMap {
  let base_topology = build_3d_grid_topology(num_nodes)
  let all_nodes = list.range(0, num_nodes - 1)

  list.fold(all_nodes, base_topology, fn(topology_map, node_id) {
    case dict.get(topology_map, node_id) {
      Ok(current_neighbors) -> {
        let random_neighbor =
          get_random_neighbor(node_id, current_neighbors, num_nodes)
        let updated_neighbors = [random_neighbor, ..current_neighbors]
        dict.insert(topology_map, node_id, updated_neighbors)
      }
      Error(_) -> topology_map
    }
  })
}

fn get_random_neighbor(
  node_id: Int,
  current_neighbors: List(Int),
  num_nodes: Int,
) -> Int {
  // Hash-based pseudo-random selection for consistency with actor neighbor selection
  let excluded_set = set.from_list([node_id, ..current_neighbors])
  let all_nodes = list.range(0, num_nodes - 1)
  let available_neighbors =
    list.filter(all_nodes, fn(id) { !set.contains(excluded_set, id) })

  case available_neighbors {
    [] -> node_id
    // Fallback if no available neighbors
    neighbors -> {
      let random_seed = node_id * 31 + num_nodes * 17 + 42
      let neighbor_index = random_seed % list.length(neighbors)
      case list.drop(neighbors, neighbor_index) |> list.first() {
        Ok(neighbor_id) -> neighbor_id
        Error(_) ->
          case list.first(neighbors) {
            Ok(neighbor_id) -> neighbor_id
            Error(_) -> node_id
          }
      }
    }
  }
}
