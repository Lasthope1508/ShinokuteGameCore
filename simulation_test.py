import random

SIZE = 9
QUADRANT_SIZE = 3

def would_cause_too_many(pos, occupied, max_per_line, max_per_quad):
    x, y = pos
    # Row check
    row_count = sum(1 for p in occupied if p[1] == y)
    if row_count >= max_per_line:
        return True
    
    # Col check
    col_count = sum(1 for p in occupied if p[0] == x)
    if col_count >= max_per_line:
        return True
        
    # Quadrant check
    qx, qy = x // 3, y // 3
    quad_count = sum(1 for p in occupied if p[0] // 3 == qx and p[1] // 3 == qy)
    if quad_count >= max_per_quad:
        return True
        
    return False

def run_simulation(count, max_per_line, max_per_quad):
    all_positions = [(x, y) for y in range(SIZE) for x in range(SIZE)]
    random.shuffle(all_positions)
    
    occupied = []
    for pos in all_positions:
        if len(occupied) >= count:
            break
        if would_cause_too_many(pos, occupied, max_per_line, max_per_quad):
            continue
        occupied.append(pos)
        
    return len(occupied)

# Let's test with different parameters 10000 times
test_cases = [
    (22, 3, 3),
    (24, 3, 3),
    (24, 4, 4),
    (25, 4, 4),
]

for count, max_line, max_quad in test_cases:
    successes = 0
    total = 10000
    counts = []
    for _ in range(total):
        res = run_simulation(count, max_line, max_quad)
        counts.append(res)
        if res == count:
            successes += 1
    avg = sum(counts) / len(counts)
    min_val = min(counts)
    print(f"Target: {count}, MaxLine: {max_line}, MaxQuad: {max_quad} -> Success Rate: {successes/total*100:.2f}%, Avg: {avg:.2f}, Min: {min_val}")
