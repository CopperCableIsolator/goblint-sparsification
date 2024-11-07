import matplotlib.pyplot as plt
import numpy as np
import json

percentages = False

with open("function_counts.json", "r") as file:
    json_obj = json.load(file)

data = json_obj["data"]
total_count = json_obj["trace_count"]
plt.rcdefaults()

objects = data.keys()
if percentages is True:
    counts = list(map(lambda x: x/total_count, data.values()))
else:
    counts = data.values()

y_pos = np.arange(len(objects))

plt.bar(y_pos, counts, align="center", alpha=0.5)
plt.xticks(y_pos, objects, rotation=90)
plt.tight_layout()

plt.show()
