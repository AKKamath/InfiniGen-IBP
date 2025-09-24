import re
import sys
import matplotlib.pyplot as plt
import numpy as np

# Assign each system a unique pair of colors: (cache_color, other_color)
system_colors = {
    "InfiniGen + IBP": ('xkcd:rust', 'tab:orange'),
    "InfiniGen": ('xkcd:army green', 'tab:green'),
}

systems = [
    "InfiniGen + IBP",
    "InfiniGen",
]

def extract(file_path):
    results = {}
    with open(file_path, 'r') as file:
        for line in file.readlines():
            match = re.match(
                r'([\w\s+]+): Model: [\w\d]+/([.\w\-\d]+) Total: (\d+\.\d+) Prefill: (\d+\.\d+) Decode: (\d+\.\d+) Cache time: (\d+\.\d+)',
                line)
            if match:
                sysname = match.group(1).strip()
                model = match.group(2).upper()
                total = float(match.group(3))
                cache_time = float(match.group(6))

                if model not in results:
                    results[model] = {}
                results[model][sysname] = (cache_time, total)
    return results


def main():
    file = sys.argv[1]
    output = sys.argv[2]
    results = extract(file)

    models = results.keys()
    n_models = len(models)
    n_systems = len(systems)

    bar_height = 0.35
    spacing = 0.5
    group_height = n_systems * bar_height
    indices = np.arange(n_models) * (group_height + spacing)

    fig, ax = plt.subplots(figsize=(10, max(4, n_models * 1.4)))

    for i, system in enumerate(systems):
        cache_times = []
        other_times = []
        y_pos = indices + i * bar_height

        for model in models:
            if system in results[model]:
                cache = results[model][system][0]
                total = results[model][system][1]
                other = total - cache
            else:
                cache = 0
                other = 0
            cache_times.append(cache)
            other_times.append(other)

        cache_color, other_color = system_colors[system]

        # Non-cache part
        ax.barh(y_pos, other_times, bar_height, left=cache_times, color=other_color, edgecolor='black', label=f"{system} (other)")
        # Cache part
        ax.barh(y_pos, cache_times, bar_height, color=cache_color, edgecolor='black', label=f"{system} (cache)")

    # Set y-axis ticks in the middle of each group
    group_centers = indices + (group_height - bar_height) / 2
    ax.set_yticks(group_centers)
    ax.set_yticklabels(models, fontweight='bold', fontsize=12)
    ax.grid(True, axis='x', linestyle='--', alpha=0.7)

    ax.set_xlabel("Latency (s)", fontweight='bold', fontsize=16)
    ax.set_ylabel("Model", fontweight='bold', fontsize=16)

    # Legend: 4 entries (2 systems × 2 parts)
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, 1.1),
              ncol=2, frameon=True, prop={'weight': 'bold', 'size': 13}, reverse=True)

    plt.tight_layout()
    plt.savefig(output + ".pdf", bbox_inches='tight', pad_inches=0.1)
    plt.close()


if __name__ == "__main__":
    main()
