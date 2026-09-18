import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import types.{type SupervisorMessage, NodeTerminated}

pub type GossipMessage {
  Rumor(content: String)
  UpdateNeighbors(neighbors: dict.Dict(Int, Subject(GossipMessage)))
  Terminate
}

pub type GossipState {
  GossipState(
    node_id: Int,
    neighbors: List(Int),
    rumor_count: Int,
    rumor_content: String,
    neighbor_subjects: dict.Dict(Int, Subject(GossipMessage)),
    supervisor: Subject(SupervisorMessage),
  )
}

pub fn start_gossip_actor(
  node_id: Int,
  neighbors: List(Int),
  supervisor: Subject(SupervisorMessage),
) -> Result(actor.Started(Subject(GossipMessage)), actor.StartError) {
  let initial_state =
    GossipState(
      node_id: node_id,
      neighbors: neighbors,
      rumor_count: 0,
      rumor_content: "",
      neighbor_subjects: dict.new(),
      supervisor: supervisor,
    )

  actor.new(initial_state)
  |> actor.on_message(handle_gossip_message)
  |> actor.start()
}

fn handle_gossip_message(
  state: GossipState,
  message: GossipMessage,
) -> actor.Next(GossipState, GossipMessage) {
  case message {
    Rumor(content) -> {
      let new_count = state.rumor_count + 1

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
            GossipState(..state, rumor_count: new_count, rumor_content: content)
          forward_rumor_to_random_neighbor(updated_state, content)
          actor.continue(updated_state)
        }
      }
    }

    UpdateNeighbors(neighbor_subjects) -> {
      let updated_state =
        GossipState(..state, neighbor_subjects: neighbor_subjects)
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

fn forward_rumor_to_random_neighbor(state: GossipState, content: String) -> Nil {
  case state.neighbors {
    [] -> Nil
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
        Ok(neighbor_subject) -> process.send(neighbor_subject, Rumor(content))
        Error(_) -> Nil
      }
    }
  }
}

pub fn update_neighbor_subjects(
  actor_subject: Subject(GossipMessage),
  neighbor_subjects: dict.Dict(Int, Subject(GossipMessage)),
) -> Nil {
  process.send(actor_subject, UpdateNeighbors(neighbor_subjects))
}
