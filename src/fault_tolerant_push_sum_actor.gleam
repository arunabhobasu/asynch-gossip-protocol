import fault_tolerant_gossip_actor.{type NodeHealth, Dead, Healthy, Suspected}
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import types.{type SupervisorMessage, NodeTerminated}

pub type FaultTolerantPushSumMessage {
  Push(s: Float, w: Float)
  UpdateNeighbors(
    neighbor_subjects: dict.Dict(Int, Subject(FaultTolerantPushSumMessage)),
  )
  Ping(from_node_id: Int)
  Pong(from_node_id: Int)
  Start
  Terminate
}

pub type FaultTolerantPushSumState {
  FaultTolerantPushSumState(
    node_id: Int,
    s: Float,
    w: Float,
    neighbors: List(Int),
    neighbor_subjects: dict.Dict(Int, Subject(FaultTolerantPushSumMessage)),
    supervisor: Subject(SupervisorMessage),
    previous_ratios: List(Float),
    max_strikes: Int,
    node_health: dict.Dict(Int, NodeHealth),
  )
}

pub fn start_fault_tolerant_push_sum_actor(
  node_id: Int,
  neighbors: List(Int),
  supervisor: Subject(SupervisorMessage),
  max_strikes: Int,
) -> Result(
  actor.Started(Subject(FaultTolerantPushSumMessage)),
  actor.StartError,
) {
  let initial_state =
    FaultTolerantPushSumState(
      node_id: node_id,
      s: int.to_float(node_id),
      w: 1.0,
      neighbors: neighbors,
      neighbor_subjects: dict.new(),
      supervisor: supervisor,
      previous_ratios: [],
      max_strikes: max_strikes,
      node_health: dict.new(),
    )

  actor.new(initial_state)
  |> actor.on_message(handle_fault_tolerant_push_sum_message)
  |> actor.start()
}

fn handle_fault_tolerant_push_sum_message(
  state: FaultTolerantPushSumState,
  message: FaultTolerantPushSumMessage,
) -> actor.Next(FaultTolerantPushSumState, FaultTolerantPushSumMessage) {
  case message {
    Push(received_s, received_w) -> {
      let new_s = state.s +. received_s
      let new_w = state.w +. received_w
      let current_ratio = new_s /. new_w
      let updated_ratios =
        [current_ratio, ..state.previous_ratios] |> list.take(3)

      case check_convergence(updated_ratios) {
        True -> {
          io.println(
            "Node "
            <> int.to_string(state.node_id)
            <> " converged with ratio: "
            <> float.to_string(current_ratio),
          )
          process.send(state.supervisor, NodeTerminated(state.node_id))
          actor.stop()
        }
        False -> {
          let half_s = new_s /. 2.0
          let half_w = new_w /. 2.0
          let updated_state =
            FaultTolerantPushSumState(
              ..state,
              s: half_s,
              w: half_w,
              previous_ratios: updated_ratios,
            )

          // Send to healthy neighbors only
          push_to_healthy_neighbor(updated_state, half_s, half_w)
          actor.continue(updated_state)
        }
      }
    }

    Start -> {
      let half_s = state.s /. 2.0
      let half_w = state.w /. 2.0
      let updated_state =
        FaultTolerantPushSumState(..state, s: half_s, w: half_w)

      push_to_healthy_neighbor(updated_state, half_s, half_w)
      actor.continue(updated_state)
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
        FaultTolerantPushSumState(..state, node_health: updated_health)
      actor.continue(updated_state)
    }

    UpdateNeighbors(neighbor_subjects) -> {
      // Initialize health status for all neighbors
      let initial_health =
        list.fold(dict.keys(neighbor_subjects), dict.new(), fn(acc, node_id) {
          dict.insert(acc, node_id, Healthy)
        })

      let updated_state =
        FaultTolerantPushSumState(
          ..state,
          neighbor_subjects: neighbor_subjects,
          node_health: initial_health,
        )

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

fn check_convergence(ratios: List(Float)) -> Bool {
  case ratios {
    [r1, r2, r3] -> {
      let diff1 = float.absolute_value(r1 -. r2)
      let diff2 = float.absolute_value(r2 -. r3)
      diff1 <. 0.0000000001 && diff2 <. 0.0000000001
    }
    _ -> False
  }
}

fn push_to_healthy_neighbor(
  state: FaultTolerantPushSumState,
  s: Float,
  w: Float,
) -> Nil {
  let healthy_neighbors = get_healthy_neighbors_push_sum(state)

  case healthy_neighbors {
    [] -> {
      io.println(
        "Node "
        <> int.to_string(state.node_id)
        <> " has no healthy neighbors for push-sum",
      )
      Nil
    }
    neighbors -> {
      let push_count = list.length(state.previous_ratios) + 1
      let random_seed = state.node_id * 31 + push_count * 17 + 42
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
          process.send(neighbor_subject, Push(s, w))
          io.println(
            "Node "
            <> int.to_string(state.node_id)
            <> " pushed to healthy node "
            <> int.to_string(selected_neighbor)
            <> " (s="
            <> float.to_string(s)
            <> ", w="
            <> float.to_string(w)
            <> ")",
          )
        }
        Error(_) -> Nil
      }
    }
  }
}

fn get_healthy_neighbors_push_sum(state: FaultTolerantPushSumState) -> List(Int) {
  list.filter(state.neighbors, fn(neighbor_id) {
    case dict.get(state.node_health, neighbor_id) {
      Ok(Healthy) -> True
      Ok(Suspected(_)) -> True
      // Still try suspected nodes
      Ok(Dead) -> False
      Error(_) -> True
      // If no health info, assume healthy
    }
  })
}

pub fn update_fault_tolerant_push_sum_neighbor_subjects(
  actor_subject: Subject(FaultTolerantPushSumMessage),
  neighbor_subjects: dict.Dict(Int, Subject(FaultTolerantPushSumMessage)),
) -> Nil {
  process.send(actor_subject, UpdateNeighbors(neighbor_subjects))
}
