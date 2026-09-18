import fault_tolerant_gossip_actor.{type FaultTolerantGossipMessage}
import fault_tolerant_push_sum_actor.{type FaultTolerantPushSumMessage}
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/io
import gleam/list

// Simple function to kill one random node from a list of gossip nodes
pub fn kill_random_gossip_node(
  gossip_nodes: dict.Dict(Int, Subject(FaultTolerantGossipMessage)),
) -> Nil {
  let node_ids = dict.keys(gossip_nodes)
  case list.length(node_ids) {
    0 -> {
      io.println("WARNING: No gossip nodes available to kill")
      Nil
    }
    count -> {
      // Simple pseudo-random selection
      let random_seed = 173 * count + 1009
      let target_index = random_seed % count

      case list.drop(node_ids, target_index) |> list.first() {
        Ok(target_node_id) -> {
          case dict.get(gossip_nodes, target_node_id) {
            Ok(target_subject) -> {
              io.println("")
              io.println(
                "FAULT INJECTION: Killing gossip node "
                <> int.to_string(target_node_id),
              )
              process.send(
                target_subject,
                fault_tolerant_gossip_actor.Terminate,
              )
              io.println(
                "Node "
                <> int.to_string(target_node_id)
                <> " has been terminated successfully!",
              )
              io.println(
                "Other nodes will detect this failure through strike counting mechanism",
              )
              io.println("")
            }
            Error(_) -> {
              io.println(
                "ERROR: Failed to get subject for gossip node "
                <> int.to_string(target_node_id),
              )
            }
          }
        }
        Error(_) -> {
          io.println("ERROR: Failed to select random gossip node")
        }
      }
    }
  }
}

// Simple function to kill one random node from a list of push-sum nodes
pub fn kill_random_push_sum_node(
  push_sum_nodes: dict.Dict(Int, Subject(FaultTolerantPushSumMessage)),
) -> Nil {
  let node_ids = dict.keys(push_sum_nodes)
  case list.length(node_ids) {
    0 -> {
      io.println("WARNING: No push-sum nodes available to kill")
      Nil
    }
    count -> {
      // Simple pseudo-random selection
      let random_seed = 173 * count + 1009
      let target_index = random_seed % count

      case list.drop(node_ids, target_index) |> list.first() {
        Ok(target_node_id) -> {
          case dict.get(push_sum_nodes, target_node_id) {
            Ok(target_subject) -> {
              io.println("")
              io.println(
                "FAULT INJECTION: Killing push-sum node "
                <> int.to_string(target_node_id),
              )
              process.send(
                target_subject,
                fault_tolerant_push_sum_actor.Terminate,
              )
              io.println(
                "Node "
                <> int.to_string(target_node_id)
                <> " has been terminated successfully!",
              )
              io.println(
                "Other nodes will detect this failure through strike counting mechanism",
              )
              io.println("")
            }
            Error(_) -> {
              io.println(
                "ERROR: Failed to get subject for push-sum node "
                <> int.to_string(target_node_id),
              )
            }
          }
        }
        Error(_) -> {
          io.println("ERROR: Failed to select random push-sum node")
        }
      }
    }
  }
}
