# Project 2 : To determine the convergence of Asynch Gossip algorithm through a simulator based on actors written in Gleam
Team Members : Arunabho Basu
---------------------------------------

## What's Working : 
- Implemented both Gossip and Push Sum algo
- Implemented all four topologies : full, 3d, line and imp3d
- Gossip algo node is terminated after it has heard rumor 10 times
- Push sum algo node is terminated after s/w ratio (tracked from previous times) haven't changed by more than
10^(-10) over past 3 rounds
---------------------------------------
### Largest size tested : 900 (only perfect squares were tested so it forms perfect grids, and 30x30 was the largest)
---------------------------------------

## Usage : 

gleam run -- numNodes(any integer) topology(full, 3d, line, imp3D) algorithm (gossip, push-sum)

example : 
gleam run -- 256 full gossip

benchmarks and plot generation script in /benchmark_results
dependencies : requires python 3.12, matplotlib and pandas


--------------------------------------
## Bonus :

Fault tolerance : every node pings its neighbors routinely to keep track of its health
Fault tolerance metric n : if N number of pings are not ponged, that node is marked as dead
Fault failover : when a node is marked dead, it is omitted from network and neighbors are recalibrated accordingly

Usage : 
gleam run -- numNodes(any integer) topology(full, 3d, line, imp3D) algorithm (gossip, push-sum) fault_tolerance_metric

