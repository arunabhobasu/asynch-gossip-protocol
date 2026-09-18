// Shared types used across the gossip and push-sum simulation
pub type SupervisorMessage {
  NodeTerminated(node_id: Int)
  RegisterNodes(nodes: List(Int))
}

// Message type for convergence notification to main process
pub type ConvergenceMessage {
  ConvergenceAchieved(elapsed_ms: Int)
}
