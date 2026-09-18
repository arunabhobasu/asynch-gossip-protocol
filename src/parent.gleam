import fault_injector
import fault_tolerant_gossip_actor
import fault_tolerant_push_sum_actor
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gossip_actor
import push_sum_actor
import topology.{type TopologyMap}
import types.{
  type ConvergenceMessage, type SupervisorMessage, ConvergenceAchieved,
  NodeTerminated, RegisterNodes,
}

pub type SupervisorState {
  SupervisorState(
    active_nodes: dict.Dict(Int, Subject(gossip_actor.GossipMessage)),
    total_nodes: Int,
    start_time: Int,
    caller: Subject(ConvergenceMessage),
  )
}

pub type PushSumSupervisorState {
  PushSumSupervisorState(
    active_nodes: dict.Dict(Int, Subject(push_sum_actor.PushSumMessage)),
    total_nodes: Int,
    start_time: Int,
    caller: Subject(ConvergenceMessage),
  )
}

pub fn start_gossip_simulation(
  num_nodes: Int,
  topology_map: TopologyMap,
  caller: Subject(ConvergenceMessage),
) -> Nil {
  // First create a temporary supervisor to get the supervisor subject
  case start_gossip_supervisor(num_nodes, caller) {
    Ok(supervisor_started) -> {
      let supervisor_subject = supervisor_started.data

      // Start all gossip actors with the supervisor
      let node_subjects =
        start_gossip_actors(num_nodes, topology_map, supervisor_subject)

      // Register the nodes - we'll modify the handler to not create dummy subjects
      let node_ids = dict.keys(node_subjects)
      process.send(supervisor_subject, RegisterNodes(node_ids))

      // Update all actors with their neighbor subjects
      update_gossip_neighbors(node_subjects, topology_map)

      // Start the gossip by sending the initial rumor to the first node
      case dict.get(node_subjects, 0) {
        Ok(first_node) -> {
          process.send(
            first_node,
            gossip_actor.Rumor("Hello, this is the gossip!"),
          )
        }
        Error(_) -> {
          io.println("Failed to start gossip simulation - no nodes available")
        }
      }
    }
    Error(_) -> {
      io.println("Failed to start gossip supervisor")
    }
  }
}

pub fn start_push_sum_simulation(
  num_nodes: Int,
  topology_map: TopologyMap,
  caller: Subject(ConvergenceMessage),
) -> Nil {
  case start_push_sum_supervisor(num_nodes, caller) {
    Ok(supervisor_started) -> {
      let supervisor_subject = supervisor_started.data

      // Start all push-sum actors
      let node_subjects =
        start_push_sum_actors(num_nodes, topology_map, supervisor_subject)

      // Register the active nodes with the supervisor
      let node_ids = dict.keys(node_subjects)
      process.send(supervisor_subject, RegisterNodes(node_ids))

      // Update all actors with their neighbor subjects
      update_push_sum_neighbors(node_subjects, topology_map)

      // Start the push-sum by telling the first node to start
      case dict.get(node_subjects, 0) {
        Ok(first_node) -> {
          process.send(first_node, push_sum_actor.Start)
        }
        Error(_) -> {
          io.println("Failed to start push-sum simulation - no nodes available")
        }
      }
    }
    Error(_) -> {
      io.println("Failed to start push-sum supervisor")
    }
  }
}

fn start_gossip_supervisor(
  num_nodes: Int,
  caller: Subject(ConvergenceMessage),
) -> Result(actor.Started(Subject(SupervisorMessage)), actor.StartError) {
  let initial_state =
    SupervisorState(
      active_nodes: dict.new(),
      total_nodes: num_nodes,
      start_time: get_current_time_millis(),
      caller: caller,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_gossip_supervisor_message)
  |> actor.start()
}

fn start_push_sum_supervisor(
  num_nodes: Int,
  caller: Subject(ConvergenceMessage),
) -> Result(actor.Started(Subject(SupervisorMessage)), actor.StartError) {
  let initial_state =
    PushSumSupervisorState(
      active_nodes: dict.new(),
      total_nodes: num_nodes,
      start_time: get_current_time_millis(),
      caller: caller,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_push_sum_supervisor_message)
  |> actor.start()
}

fn handle_gossip_supervisor_message(
  state: SupervisorState,
  message: SupervisorMessage,
) -> actor.Next(SupervisorState, SupervisorMessage) {
  case message {
    RegisterNodes(node_list) -> {
      let active_dict =
        list.fold(node_list, dict.new(), fn(acc, node_id) {
          dict.insert(acc, node_id, process.new_subject())
        })
      let updated_state = SupervisorState(..state, active_nodes: active_dict)
      actor.continue(updated_state)
    }
    NodeTerminated(node_id) -> {
      let updated_nodes = dict.delete(state.active_nodes, node_id)
      let remaining_count = dict.size(updated_nodes)

      io.println(
        "Node "
        <> int.to_string(node_id)
        <> " terminated. "
        <> int.to_string(remaining_count)
        <> " nodes remaining.",
      )

      let converged_count = state.total_nodes - remaining_count
      let convergence_threshold = 1
      case converged_count >= convergence_threshold {
        True -> {
          let end_time = get_current_time_millis()
          let duration = end_time - state.start_time
          io.println(
            "Simulation complete - at least one node reached convergence ("
            <> int.to_string(converged_count)
            <> "/"
            <> int.to_string(state.total_nodes)
            <> " nodes)",
          )
          process.send(state.caller, ConvergenceAchieved(duration))
          actor.stop()
        }
        False -> {
          let updated_state =
            SupervisorState(..state, active_nodes: updated_nodes)
          actor.continue(updated_state)
        }
      }
    }
  }
}

fn handle_push_sum_supervisor_message(
  state: PushSumSupervisorState,
  message: SupervisorMessage,
) -> actor.Next(PushSumSupervisorState, SupervisorMessage) {
  case message {
    RegisterNodes(node_list) -> {
      let active_dict =
        list.fold(node_list, dict.new(), fn(acc, node_id) {
          dict.insert(acc, node_id, process.new_subject())
        })
      let updated_state =
        PushSumSupervisorState(..state, active_nodes: active_dict)
      actor.continue(updated_state)
    }
    NodeTerminated(node_id) -> {
      let updated_nodes = dict.delete(state.active_nodes, node_id)
      let remaining_count = dict.size(updated_nodes)
      let converged_count = state.total_nodes - remaining_count
      let convergence_threshold = 1

      io.println(
        "Node "
        <> int.to_string(node_id)
        <> " terminated. "
        <> int.to_string(converged_count)
        <> " nodes converged out of "
        <> int.to_string(state.total_nodes)
        <> " total nodes.",
      )

      case converged_count >= convergence_threshold {
        True -> {
          let end_time = get_current_time_millis()
          let duration = end_time - state.start_time
          io.println(
            "Simulation complete - at least one node reached convergence! "
            <> int.to_string(converged_count)
            <> " nodes converged (threshold: "
            <> int.to_string(convergence_threshold)
            <> ")",
          )
          process.send(state.caller, ConvergenceAchieved(duration))
          actor.stop()
        }
        False -> {
          let updated_state =
            PushSumSupervisorState(..state, active_nodes: updated_nodes)
          actor.continue(updated_state)
        }
      }
    }
  }
}

fn start_gossip_actors(
  num_nodes: Int,
  topology_map: TopologyMap,
  supervisor: Subject(SupervisorMessage),
) -> dict.Dict(Int, Subject(gossip_actor.GossipMessage)) {
  let node_range = list.range(0, num_nodes - 1)

  list.fold(node_range, dict.new(), fn(acc, node_id) {
    let neighbors = case dict.get(topology_map, node_id) {
      Ok(neighbor_list) -> neighbor_list
      Error(_) -> []
    }

    case gossip_actor.start_gossip_actor(node_id, neighbors, supervisor) {
      Ok(started) -> dict.insert(acc, node_id, started.data)
      Error(_) -> acc
    }
  })
}

fn start_push_sum_actors(
  num_nodes: Int,
  topology_map: TopologyMap,
  supervisor: Subject(SupervisorMessage),
) -> dict.Dict(Int, Subject(push_sum_actor.PushSumMessage)) {
  let node_range = list.range(0, num_nodes - 1)

  list.fold(node_range, dict.new(), fn(acc, node_id) {
    let neighbors = case dict.get(topology_map, node_id) {
      Ok(neighbor_list) -> neighbor_list
      Error(_) -> []
    }

    case push_sum_actor.start_push_sum_actor(node_id, neighbors, supervisor) {
      Ok(started) -> dict.insert(acc, node_id, started.data)
      Error(_) -> acc
    }
  })
}

fn update_gossip_neighbors(
  node_subjects: dict.Dict(Int, Subject(gossip_actor.GossipMessage)),
  topology_map: TopologyMap,
) -> Nil {
  dict.each(node_subjects, fn(node_id, subject) {
    case dict.get(topology_map, node_id) {
      Ok(neighbors) -> {
        let neighbor_subjects =
          dict.filter(node_subjects, fn(neighbor_id, _) {
            list.contains(neighbors, neighbor_id)
          })
        gossip_actor.update_neighbor_subjects(subject, neighbor_subjects)
      }
      Error(_) -> Nil
    }
  })
}

fn update_push_sum_neighbors(
  node_subjects: dict.Dict(Int, Subject(push_sum_actor.PushSumMessage)),
  topology_map: TopologyMap,
) -> Nil {
  dict.each(node_subjects, fn(node_id, subject) {
    case dict.get(topology_map, node_id) {
      Ok(neighbors) -> {
        let neighbor_subjects =
          dict.filter(node_subjects, fn(neighbor_id, _) {
            list.contains(neighbors, neighbor_id)
          })
        push_sum_actor.update_neighbor_subjects(subject, neighbor_subjects)
      }
      Error(_) -> Nil
    }
  })
}

// External function to get current time in nanoseconds
@external(erlang, "erlang", "system_time")
fn system_time_nanoseconds() -> Int

// Convert nanoseconds to milliseconds
fn get_current_time_millis() -> Int {
  system_time_nanoseconds() / 1_000_000
}

// FAULT-TOLERANT SIMULATION FUNCTIONS

pub fn start_fault_tolerant_gossip_simulation(
  num_nodes: Int,
  topology_map: TopologyMap,
  caller: Subject(ConvergenceMessage),
  max_strikes: Int,
) -> Nil {
  case start_gossip_supervisor(num_nodes, caller) {
    Ok(supervisor_started) -> {
      let supervisor_subject = supervisor_started.data

      let node_subjects =
        start_fault_tolerant_gossip_actors(
          num_nodes,
          topology_map,
          supervisor_subject,
          max_strikes,
        )

      let node_ids = dict.keys(node_subjects)
      process.send(supervisor_subject, RegisterNodes(node_ids))

      update_fault_tolerant_gossip_neighbors(node_subjects, topology_map)

      // Automatically kill one random node to test fault tolerance
      io.println(
        "FAULT TOLERANCE TESTING: Automatically killing one random node...",
      )
      fault_injector.kill_random_gossip_node(node_subjects)

      case dict.get(node_subjects, 0) {
        Ok(first_node) -> {
          process.send(
            first_node,
            fault_tolerant_gossip_actor.Rumor(
              "Hello, this is the fault-tolerant gossip!",
            ),
          )
        }
        Error(_) -> {
          io.println(
            "Failed to start fault-tolerant gossip simulation - no nodes available",
          )
        }
      }
    }
    Error(_) -> {
      io.println("Failed to start gossip supervisor")
    }
  }
}

pub fn start_fault_tolerant_push_sum_simulation(
  num_nodes: Int,
  topology_map: TopologyMap,
  caller: Subject(ConvergenceMessage),
  max_strikes: Int,
) -> Nil {
  case start_push_sum_supervisor(num_nodes, caller) {
    Ok(supervisor_started) -> {
      let supervisor_subject = supervisor_started.data

      let node_subjects =
        start_fault_tolerant_push_sum_actors(
          num_nodes,
          topology_map,
          supervisor_subject,
          max_strikes,
        )

      let node_ids = dict.keys(node_subjects)
      process.send(supervisor_subject, RegisterNodes(node_ids))

      update_fault_tolerant_push_sum_neighbors(node_subjects, topology_map)

      // Automatically kill one random node to test fault tolerance
      io.println(
        "FAULT TOLERANCE TESTING: Automatically killing one random node...",
      )
      fault_injector.kill_random_push_sum_node(node_subjects)

      case dict.get(node_subjects, 0) {
        Ok(first_node) -> {
          process.send(first_node, fault_tolerant_push_sum_actor.Start)
        }
        Error(_) -> {
          io.println(
            "Failed to start fault-tolerant push-sum simulation - no nodes available",
          )
        }
      }
    }
    Error(_) -> {
      io.println("Failed to start push-sum supervisor")
    }
  }
}

fn start_fault_tolerant_gossip_actors(
  num_nodes: Int,
  topology_map: TopologyMap,
  supervisor: Subject(SupervisorMessage),
  max_strikes: Int,
) -> dict.Dict(
  Int,
  Subject(fault_tolerant_gossip_actor.FaultTolerantGossipMessage),
) {
  let node_range = list.range(0, num_nodes - 1)

  list.fold(node_range, dict.new(), fn(acc, node_id) {
    let neighbors = case dict.get(topology_map, node_id) {
      Ok(neighbor_list) -> neighbor_list
      Error(_) -> []
    }

    case
      fault_tolerant_gossip_actor.start_fault_tolerant_gossip_actor(
        node_id,
        neighbors,
        supervisor,
        max_strikes,
      )
    {
      Ok(actor_started) -> {
        dict.insert(acc, node_id, actor_started.data)
      }
      Error(_) -> {
        io.println(
          "Failed to start fault-tolerant gossip actor "
          <> int.to_string(node_id),
        )
        acc
      }
    }
  })
}

fn start_fault_tolerant_push_sum_actors(
  num_nodes: Int,
  topology_map: TopologyMap,
  supervisor: Subject(SupervisorMessage),
  max_strikes: Int,
) -> dict.Dict(
  Int,
  Subject(fault_tolerant_push_sum_actor.FaultTolerantPushSumMessage),
) {
  let node_range = list.range(0, num_nodes - 1)

  list.fold(node_range, dict.new(), fn(acc, node_id) {
    let neighbors = case dict.get(topology_map, node_id) {
      Ok(neighbor_list) -> neighbor_list
      Error(_) -> []
    }

    case
      fault_tolerant_push_sum_actor.start_fault_tolerant_push_sum_actor(
        node_id,
        neighbors,
        supervisor,
        max_strikes,
      )
    {
      Ok(actor_started) -> {
        dict.insert(acc, node_id, actor_started.data)
      }
      Error(_) -> {
        io.println(
          "Failed to start fault-tolerant push-sum actor "
          <> int.to_string(node_id),
        )
        acc
      }
    }
  })
}

fn update_fault_tolerant_gossip_neighbors(
  node_subjects: dict.Dict(
    Int,
    Subject(fault_tolerant_gossip_actor.FaultTolerantGossipMessage),
  ),
  topology_map: TopologyMap,
) -> Nil {
  dict.each(node_subjects, fn(node_id, node_subject) {
    let neighbors = case dict.get(topology_map, node_id) {
      Ok(neighbor_list) -> neighbor_list
      Error(_) -> []
    }

    let neighbor_subjects =
      list.fold(neighbors, dict.new(), fn(acc, neighbor_id) {
        case dict.get(node_subjects, neighbor_id) {
          Ok(neighbor_subject) ->
            dict.insert(acc, neighbor_id, neighbor_subject)
          Error(_) -> acc
        }
      })

    fault_tolerant_gossip_actor.update_fault_tolerant_neighbor_subjects(
      node_subject,
      neighbor_subjects,
    )
  })
}

fn update_fault_tolerant_push_sum_neighbors(
  node_subjects: dict.Dict(
    Int,
    Subject(fault_tolerant_push_sum_actor.FaultTolerantPushSumMessage),
  ),
  topology_map: TopologyMap,
) -> Nil {
  dict.each(node_subjects, fn(node_id, node_subject) {
    let neighbors = case dict.get(topology_map, node_id) {
      Ok(neighbor_list) -> neighbor_list
      Error(_) -> []
    }

    let neighbor_subjects =
      list.fold(neighbors, dict.new(), fn(acc, neighbor_id) {
        case dict.get(node_subjects, neighbor_id) {
          Ok(neighbor_subject) ->
            dict.insert(acc, neighbor_id, neighbor_subject)
          Error(_) -> acc
        }
      })

    fault_tolerant_push_sum_actor.update_fault_tolerant_push_sum_neighbor_subjects(
      node_subject,
      neighbor_subjects,
    )
  })
}
