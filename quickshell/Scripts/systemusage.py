#!/usr/bin/env python3
import os
import time

def get_cpu_ticks():
    with open('/proc/stat', 'r') as f:
        fields = [float(column) for column in f.readline().strip().split()[1:]]
    return sum(fields)

def get_process_stats():
    procs = {}
    total_mem = 0
    with open('/proc/meminfo', 'r') as f:
        for line in f:
            if "MemTotal" in line:
                total_mem = int(line.split()[1])
                break

    for pid in os.listdir('/proc'):
        if not pid.isdigit() or pid == str(os.getpid()):
            continue
        try:
            with open(f'/proc/{pid}/stat', 'r') as f:
                stat = f.read().split()
                name_end = max([i for i, x in enumerate(stat) if x.endswith(')')])
                name = " ".join(stat[1:name_end+1])[1:-1]
                utime = int(stat[name_end + 12])
                stime = int(stat[name_end + 13])
                
            with open(f'/proc/{pid}/statm', 'r') as f:
                rss = int(f.read().split()[1]) * (os.sysconf('SC_PAGESIZE') / 1024 / 1024)

            procs[pid] = {'name': name, 'cpu_time': utime + stime, 'rss': rss}
        except FileNotFoundError:
            continue
    return procs

sys_ticks_1 = get_cpu_ticks()
p_stats_1 = get_process_stats()

time.sleep(0.2)

sys_ticks_2 = get_cpu_ticks()
p_stats_2 = get_process_stats()

sys_delta = sys_ticks_2 - sys_ticks_1
num_cpus = os.cpu_count() or 1

cpu_list = []
mem_list = []

for pid, stats2 in p_stats_2.items():
    if pid in p_stats_1 and sys_delta > 0:
        proc_delta = stats2['cpu_time'] - p_stats_1[pid]['cpu_time']
        cpu_pct = (proc_delta / sys_delta) * 100
        cpu_list.append((stats2['name'].replace(" ", "_"), pid, round(cpu_pct, 1)))
    mem_list.append((stats2['name'].replace(" ", "_"), pid, round(stats2['rss'], 1)))

for item in sorted(cpu_list, key=lambda x: x[2], reverse=True)[:3]:
    print(f"{item[0]} {item[1]} {item[2]}%")

for item in sorted(mem_list, key=lambda x: x[2], reverse=True)[:3]:
    print(f"{item[0]} {item[1]} {item[2]}M")
