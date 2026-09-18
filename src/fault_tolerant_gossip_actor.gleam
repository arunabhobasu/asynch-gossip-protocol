import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import types.{type SupervisorMessage, NodeTerminated}

pub type FaultTolerantGossipMessage {
  Rumor(content: String)
  UpdateNeighbors(
    neighbor_subjects: dict.Dict(Int, Subject(FaultTolerantGossipMessage)),
  )
  Ping(from_node_id: Int)
  Pong(from_node_id: Int)
  Terminate
}

pub type NodeHealth {
  Healthy
  Suspected(strike_count: Int)
  Dead
}

pub type FaultTolerantGossipState {
  FaultTolerantGossipState(
    node_id: Int,
    rumor_count: Int,
    rumor_content: String,
    neighbors: List(Int),
    neighbor_subjects: dict.Dict(Int, Subject(FaultTolerantGossipMessage)),
    supervisor: Subject(SupervisorMessage),
    max_strikes: Int,
    node_health: dict.Dict(Int, NodeHealth),
    last_ping_time: dict.Dict(Int, Int),
  )
}

pub fn start_fault_tolerant_gossip_actor(
  node_id: Int,
  neighbors: List(Int),
  supervisor: Subject(SupervisorMessage),
  max_strikes: Int,
) -> Result(
  actor.Started(Subject(FaultTolerantGossipMessage)),
  actor.StartError,
) {
  let initial_state =
    FaultTolerantGossipState(
      node_id: node_id,
      rumor_count: 0,
      rumor_content: "",
      neighbors: neighbors,
      neighbor_subjects: dict.new(),
      supervisor: supervisor,
      max_strikes: max_strikes,
      node_health: dict.new(),
      last_ping_time: dict.new(),
    )

  actor.new(initial_state)
  |> actor.on_message(handle_fault_tolerant_gossip_message)
  |> actor.start()
}

fn handle_fault_tolerant_gossip_message(
  state: FaultTolerantGossipState,
  message: FaultTolerantGossipMessage,
) -> actor.Next(FaultTolerantGossipState, FaultTolerantGossipMessage) {
  case message {
    Rumor(content) -> {
      let new_count = state.rumor_count + 1

      // Send pong back to acknowledge rumor receipt
      forward_rumor_with_fault_tolerance(state, content)

      case new_count >= 10 {
        True -> {
          io.println(
            "Node "
            <> int.to_string(state.node_id)
            <> " terminating after hearing rumor "
            <> int.to_string(new_count)
            <> " times",
          )
          process.send(state.supervisor, NodeTerminated(state.node_id))
          actor.stop()
        }
        False -> {
          let updated_state =
            FaultTolerantGossipState(
              ..state,
              rumor_count: new_count,
              rumor_content: content,
            )
          actor.continue(updated_state)
        }
      }
    }

    Ping(from_node_id) -> {
      // Respond with pong
      case dict.get(state.neighbor_subjects, from_node_id) {
        Ok(neighbor_subject) -> {
          process.send(neighbor_subject, Pong(state.node_id))
        }
        Error(_) -> Nil
      }
      actor.continue(state)
    }

    Pong(from_node_id) -> {
      // Mark node as healthy - reset strike count
      let updated_health = dict.insert(state.node_health, from_node_id, Healthy)
      let updated_state =
        FaultTolerantGossipState(..state, node_health: updated_health)
      actor.continue(updated_state)
    }

    UpdateNeighbors(neighbor_subjects) -> {
      // Initialize health status for all neighbors
      let initial_health =
        list.fold(dict.keys(neighbor_subjects), dict.new(), fn(acc, node_id) {
          dict.insert(acc, node_id, Healthy)
        })

      let updated_state =
        FaultTolerantGossipState(
          ..state,
          neighbor_subjects: neighbor_subjects,
          node_health: initial_health,
        )

      // Start periodic health checks
      start_periodic_health_check(updated_state)
      actor.continue(updated_state)
    }

    Terminate -> {
      io.println(
        "Node " <> int.to_string(state.node_id) <> " forced termination",
      )
      actor.stop()
    }
  }
}

fn forward_rumor_with_fault_tolerance(
  state: FaultTolerantGossipState,
  content: String,
) -> Nil {
  let healthy_neighbors = get_healthy_neighbors(state)

  case healthy_neighbors {
    [] -> {
      io.println(
        "Node "
        <> int.to_string(state.node_id)
        <> " has no healthy neighbors to forward rumor to",
      )
      Nil
    }
    neighbors -> {
      let random_seed = state.node_id * 127 + state.rumor_count * 73 + 1009
      let neighbor_index = random_seed % list.length(neighbors)
      let selected_neighbor = case
        list.drop(neighbors, neighbor_index) |> list.first()
      {
        Ok(neighbor_id) -> neighbor_id
        Error(_) ->
          case list.first(neighbors) {
            Ok(neighbor_id) -> neighbor_id
            Error(_) -> state.node_id
          }
      }

      case dict.get(state.neighbor_subjects, selected_neighbor) {
        Ok(neighbor_subject) -> {
          process.send(neighbor_subject, Rumor(content))
          io.println(
            "Node "
            <> int.to_string(state.node_id)
            <> " forwarded rumor to healthy node "
            <> int.to_string(selected_neighbor),
          )
        }
        Error(_) -> Nil
      }
    }
  }
}

fn get_healthy_neighbors(state: FaultTolerantGossipState) -> List(Int) {
  list.filter(state.neighbors, fn(neighbor_id) {
    case dict.get(state.node_health, neighbor_id) {
      Ok(Healthy) -> True
      Ok(Suspected(_)) -> True
      // Still try suspected nodes, but they're being monitored
      Ok(Dead) -> False
      Error(_) -> True
      // If no health info, assume healthy
    }
  })
}

fn start_periodic_health_check(state: FaultTolerantGossipState) -> Nil {
  // Send ping to all neighbors to check their health
  list.each(state.neighbors, fn(neighbor_id) {
    case dict.get(state.neighbor_subjects, neighbor_id) {
      Ok(neighbor_subject) -> {
        process.send(neighbor_subject, Ping(state.node_id))
      }
      Error(_) -> Nil
    }
  })
}

pub fn update_fault_tolerant_neighbor_subjects(
  actor_subject: Subject(FaultTolerantGossipMessage),
  neighbor_subjects: dict.Dict(Int, Subject(FaultTolerantGossipMessage)),
) -> Nil {
  process.send(actor_subject, UpdateNeighbors(neighbor_subjects))
}
