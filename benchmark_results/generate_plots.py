import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os

# Set up the plotting style
plt.style.use('default')
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10

algorithms = ['gossip', 'push-sum']
topologies = ['full', '3D', 'line', 'imp3D']

# Color scheme for topologies
colors = {'full': '#1f77b4', '3D': '#ff7f0e', 'line': '#2ca02c', 'imp3D': '#d62728'}
markers = {'full': 'o', '3D': 's', 'line': '^', 'imp3D': 'D'}
line_styles = {'full': '-', '3D': '--', 'line': '-.', 'imp3D': ':'}

topology_names = {'full': 'Full Network', '3D': '3D Grid', 'line': 'Line', 'imp3D': 'Imperfect 3D'}

for algorithm in algorithms:
    plt.figure(figsize=(12, 8))
    
    # Read data
    csv_file = f'convergence_{algorithm}.csv'
    if not os.path.exists(csv_file):
        print(f"CSV file not found: {csv_file}")
        continue
        
    df = pd.read_csv(csv_file)
    
    # Plot each topology
    for topology in topologies:
        if topology in df.columns:
            # Filter out N/A values
            valid_data = df[df[topology] != 'N/A'].copy()
            if len(valid_data) > 0:
                valid_data[topology] = pd.to_numeric(valid_data[topology])
                
                plt.plot(valid_data['NetworkSize'], valid_data[topology], 
                        color=colors[topology], 
                        linestyle=line_styles[topology],
                        marker=markers[topology],
                        markersize=6,
                        linewidth=2,
                        label=topology_names[topology],
                        alpha=0.8)
    
    plt.xlabel('Network Size (Number of Nodes)', fontsize=12, fontweight='bold')
    plt.ylabel('Convergence Time (milliseconds)', fontsize=12, fontweight='bold')
    plt.title(f'{algorithm.upper()} Algorithm: Convergence Time vs Network Size\\n(Terminates when first node reaches convergence)', 
              fontsize=14, fontweight='bold', pad=20)
    
    plt.grid(True, alpha=0.3, linestyle='-', linewidth=0.5)
    plt.legend(loc='best', frameon=True, fancybox=True, shadow=True, fontsize=10)
    
    # Set reasonable axis limits
    plt.xlim(0, max(df['NetworkSize']) + 20)
    plt.ylim(bottom=0)
    
    plt.tight_layout()
    
    # Save the plot
    plot_file = f'convergence_plot_{algorithm}.png'
    plt.savefig(plot_file, dpi=300, bbox_inches='tight', facecolor='white')
    print(f"Plot saved: {plot_file}")
    
    plt.show()

print("All plots generated successfully!")
