import numpy as np

n_samples = 128
max_val = 511  # maximum value for 9-bit data
x = np.array(range(n_samples))
# Generate angles from 0 to pi/2 for a quarter cycle
y = np.round(max_val * np.sin((np.pi/2) * x / (n_samples - 1)))
y = [int(v) for v in y]

with open('sine_quarter.txt', 'w') as f:
    for v in y:
        f.write(f'{v:03x}\n')
