import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import types.{type SupervisorMessage, NodeTerminated}

pub type PushSumMessage {
  Push(s: Float, w: Float)
  UpdateNeighbors(neighbors: dict.Dict(Int, Subject(PushSumMessage)))
  Start
  Terminate
}

pub type PushSumState {
  PushSumState(
    node_id: Int,
    neighbors: List(Int),
    s: Float,
    // sum
    w: Float,
    // weight
    previous_ratios: List(Float),
    // track last 3 ratios for convergence
    neighbor_subjects: dict.Dict(Int, Subject(PushSumMessage)),
    supervisor: Subject(SupervisorMessage),
  )
}

pub fn start_push_sum_actor(
  node_id: Int,
  neighbors: List(Int),
  supervisor: Subject(SupervisorMessage),
) -> Result(actor.Started(Subject(PushSumMessage)), actor.StartError) {
  let initial_state =
    PushSumState(
      node_id: node_id,
      neighbors: neighbors,
      s: int.to_float(node_id),
      w: 1.0,
      previous_ratios: [],
      neighbor_subjects: dict.new(),
      supervisor: supervisor,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_push_sum_message)
  |> actor.start()
}

fn handle_push_sum_message(
  state: PushSumState,
  message: PushSumMessage,
) -> actor.Next(PushSumState, PushSumMessage) {
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
            PushSumState(
              ..state,
              s: half_s,
              w: half_w,
              previous_ratios: updated_ratios,
            )
          send_to_random_neighbor(updated_state, half_s, half_w)
          actor.continue(updated_state)
        }
      }
    }

    Start -> {
      let half_s = state.s /. 2.0
      let half_w = state.w /. 2.0
      let updated_state = PushSumState(..state, s: half_s, w: half_w)
      send_to_random_neighbor(updated_state, half_s, half_w)
      actor.continue(updated_state)
    }

    UpdateNeighbors(neighbor_subjects) -> {
      let updated_state =
        PushSumState(..state, neighbor_subjects: neighbor_subjects)
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

fn send_to_random_neighbor(state: PushSumState, s: Float, w: Float) -> Nil {
  case state.neighbors {
    [] -> Nil
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
        Ok(neighbor_subject) -> process.send(neighbor_subject, Push(s, w))
        Error(_) -> Nil
      }
    }
  }
}

pub fn update_neighbor_subjects(
  actor_subject: Subject(PushSumMessage),
  neighbor_subjects: dict.Dict(Int, Subject(PushSumMessage)),
) -> Nil {
  process.send(actor_subject, UpdateNeighbors(neighbor_subjects))
}
