# CONVERGENCE ANALYSIS - FINAL SUMMARY
# Generated from benchmarking gossip and push-sum algorithms
# with early termination (first node convergence) strategy

## Overview
This analysis shows convergence time vs network size for both algorithms
using perfect square network sizes from 16 to 256 nodes across 4 topologies.

## Key Implementation Details
- **Early Termination Strategy**: Simulations end when FIRST node reaches convergence
- **Gossip Algorithm**: Terminates when any node hears rumor 10 times  
- **Push-Sum Algorithm**: Terminates when any node's ratio converges
- **Network Sizes**: All perfect squares (16, 25, 36, 49, 64, 81, 100, 144, 196, 256)
- **Topologies**: Full Network, 3D Grid, Line, Imperfect 3D

## Performance Results

### Gossip Algorithm Winners:
- **Best Topology**: 3D Grid (332.9ms average)
- **Most Stable**: Line topology (minimal variance)
- **Overall Performance**: 342.9ms average across all configurations

### Push-Sum Algorithm Winners:
- **Best Topology**: Imperfect 3D (340.1ms average) 
- **Most Stable**: Line topology (consistent across sizes)
- **Overall Performance**: 345.2ms average across all configurations

### Algorithm Comparison:
- **Winner**: Gossip (1.01x faster overall)
- **Performance Difference**: Minimal (< 3ms average difference)
- **Scaling**: Both scale excellently due to early termination

## Key Insights

1. **Early Termination Effectiveness**: 
   - Convergence times remain stable regardless of network size
   - First-node convergence strategy is highly efficient
   - Network scaling has minimal performance impact

2. **Topology Impact**:
   - 3D Grid performs best for Gossip algorithm
   - Full Network shows higher variance, especially for larger networks
   - Line and Imperfect 3D show consistent mid-range performance

3. **Algorithm Characteristics**:
   - Both algorithms perform similarly with early termination
   - Gossip shows slight edge in consistency
   - Push-Sum shows more variance in Full Network topology

## Data Files
- convergence_gossip.csv: Complete gossip algorithm results
- convergence_push-sum.csv: Complete push-sum algorithm results
- generate_plots.py: Python script for matplotlib visualization
- CONVERGENCE_PLOTS_RESULTS.txt: ASCII plot visualization

## Conclusion
Early termination (first node convergence) makes both algorithms highly 
efficient and scalable, with convergence times remaining consistent 
across network sizes from 16 to 256 nodes.