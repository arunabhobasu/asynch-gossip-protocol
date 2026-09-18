import gleam/erlang/charlist
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import parent
import topology
import types.{ConvergenceAchieved}

@external(erlang, "init", "get_plain_arguments")
fn get_args_raw() -> List(charlist.Charlist)

fn get_args() -> List(String) {
  get_args_raw()
  |> list.map(charlist.to_string)
}

pub fn main() {
  let args = get_args()
  case args {
    [num_nodes_str, topology_str, algorithm_str, strike_count_str] -> {
      case int.parse(num_nodes_str) {
        Ok(num_nodes) -> {
          case parse_topology(topology_str) {
            Ok(topology_type) -> {
              case parse_algorithm(algorithm_str) {
                Ok(algorithm_type) -> {
                  case int.parse(strike_count_str) {
                    Ok(strike_count) -> {
                      case strike_count > 0 {
                        True -> {
                          run_simulation_with_fault_tolerance(
                            num_nodes,
                            topology_type,
                            algorithm_type,
                            strike_count,
                          )
                        }
                        False -> {
                          io.println("Strike count must be a positive integer")
                        }
                      }
                    }
                    Error(_) -> {
                      io.println(
                        "Invalid strike count. Must be a positive integer (e.g., 3, 4, 5)",
                      )
                    }
                  }
                }
                Error(_) -> {
                  io.println("Invalid algorithm. Use: gossip, push-sum")
                }
              }
            }
            Error(_) -> {
              io.println("Invalid topology. Use: full, 3D, line, imp3D")
            }
          }
        }
        Error(_) -> {
          io.println("Invalid number of nodes")
        }
      }
    }
    [num_nodes_str, topology_str, algorithm_str] -> {
      case int.parse(num_nodes_str) {
        Ok(num_nodes) -> {
          case parse_topology(topology_str) {
            Ok(topology_type) -> {
              case parse_algorithm(algorithm_str) {
                Ok(algorithm_type) -> {
                  run_simulation(num_nodes, topology_type, algorithm_type)
                }
                Error(_) -> {
                  io.println("Invalid algorithm. Use: gossip, push-sum")
                }
              }
            }
            Error(_) -> {
              io.println("Invalid topology. Use: full, 3D, line, imp3D")
            }
          }
        }
        Error(_) -> {
          io.println("Invalid number of nodes")
        }
      }
    }
    _ -> {
      io.println("Usage: project2 numNodes topology algorithm [strikeCount]")
      io.println("  numNodes: number of actors")
      io.println("  topology: full, 3D, line, imp3D")
      io.println("  algorithm: gossip, push-sum")
      io.println(
        "  strikeCount: (optional) dead node detection strikes (e.g., 3, 4, 5)",
      )
      io.println("Examples:")
      io.println("  gleam run 10 full gossip     # No fault tolerance")
      io.println(
        "  gleam run 10 full gossip 3   # With 3-strike fault tolerance + automatic node killing",
      )
    }
  }
}

fn parse_topology(topology_str: String) -> Result(topology.TopologyType, Nil) {
  case topology_str {
    "full" -> Ok(topology.Full)
    "3D" -> Ok(topology.Grid3D)
    "line" -> Ok(topology.Line)
    "imp3D" -> Ok(topology.ImperfectGrid3D)
    _ -> Error(Nil)
  }
}

fn parse_algorithm(algorithm_str: String) -> Result(AlgorithmType, Nil) {
  case algorithm_str {
    "gossip" -> Ok(Gossip)
    "push-sum" -> Ok(PushSum)
    _ -> Error(Nil)
  }
}

pub type AlgorithmType {
  Gossip
  PushSum
}

fn run_simulation(
  num_nodes: Int,
  topology_type: topology.TopologyType,
  algorithm_type: AlgorithmType,
) {
  io.println(
    "Simulation: "
    <> topology.to_string(topology_type)
    <> " topology with "
    <> int.to_string(num_nodes)
    <> " nodes using "
    <> algorithm_to_string(algorithm_type)
    <> " algorithm",
  )

  // Build topology
  let topology_map = topology.build_topology(num_nodes, topology_type)

  // Create convergence notification subject
  let convergence_subject = process.new_subject()

  // Start protocol
  case algorithm_type {
    Gossip -> {
      parent.start_gossip_simulation(
        num_nodes,
        topology_map,
        convergence_subject,
      )
    }
    PushSum -> {
      parent.start_push_sum_simulation(
        num_nodes,
        topology_map,
        convergence_subject,
      )
    }
  }

  // Wait for convergence notification
  case process.receive(convergence_subject, within: 600_000) {
    Ok(ConvergenceAchieved(duration_ms)) -> {
      io.println("Convergence time: " <> int.to_string(duration_ms) <> " ms")
    }
    Error(_) -> {
      io.println("Simulation timed out after 10 minutes")
    }
  }
}

fn run_simulation_with_fault_tolerance(
  num_nodes: Int,
  topology_type: topology.TopologyType,
  algorithm_type: AlgorithmType,
  strike_count: Int,
) {
  io.println(
    "Fault-Tolerant Simulation: "
    <> topology.to_string(topology_type)
    <> " topology with "
    <> int.to_string(num_nodes)
    <> " nodes using "
    <> algorithm_to_string(algorithm_type)
    <> " algorithm"
    <> " (Dead node detection: "
    <> int.to_string(strike_count)
    <> "-strike rule)",
  )

  // Build topology
  let topology_map = topology.build_topology(num_nodes, topology_type)

  // Create convergence notification subject
  let convergence_subject = process.new_subject()

  // Start fault-tolerant protocol
  case algorithm_type {
    Gossip -> {
      parent.start_fault_tolerant_gossip_simulation(
        num_nodes,
        topology_map,
        convergence_subject,
        strike_count,
      )
    }
    PushSum -> {
      parent.start_fault_tolerant_push_sum_simulation(
        num_nodes,
        topology_map,
        convergence_subject,
        strike_count,
      )
    }
  }

  // Wait for convergence notification
  case process.receive(convergence_subject, within: 600_000) {
    Ok(ConvergenceAchieved(duration_ms)) -> {
      io.println("Convergence time: " <> int.to_string(duration_ms) <> " ms")
    }
    Error(_) -> {
      io.println("Simulation timed out after 10 minutes")
    }
  }
}

fn algorithm_to_string(algorithm: AlgorithmType) -> String {
  case algorithm {
    Gossip -> "gossip"
    PushSum -> "push-sum"
  }
}
