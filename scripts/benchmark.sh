#!/bin/bash

# Install sysbench
if command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y sysbench fio
elif command -v yum &> /dev/null; then
    sudo yum install -y sysbench fio
fi

# Install Geekbench 6
wget https://cdn.geekbench.com/Geekbench-6.3.0-Linux.tar.gz
tar xf Geekbench-6.3.0-Linux.tar.gz
cd Geekbench-6.3.0-Linux

# Output system info
echo "=== System Information ==="
echo -n "CPU: "
cat /proc/cpuinfo | grep "model name" | head -n 1
echo "CPU Cores: $(nproc)"
free -h | grep "Mem:" | awk '{print "Memory: " $2}'
lsblk | grep disk | awk '{print "Disk: " $1 " " $4}'
echo "========================="

# Run Geekbench
./geekbench6

# Run benchmarks
start_time=$(date +%s)
echo -e "\nRunning CPU benchmark..."
sysbench cpu --cpu-max-prime=100000 --threads=4 run > cpu_results.txt
cpu_end=$(date +%s)
cpu_duration=$((cpu_end - start_time))

echo -e "\nRunning Memory benchmark..."
sysbench memory --memory-block-size=1K --memory-total-size=100G --memory-access-mode=seq run > memory_results.txt
mem_end=$(date +%s)
mem_duration=$((mem_end - cpu_end))

echo -e "\nRunning Disk benchmark..."
fio --name=disk_test --filename=test_file --size=4G \
    --rw=randrw --rwmixread=70 --ioengine=libaio --bs=4k \
    --direct=1 --iodepth=32 --numjobs=4 --runtime=60 \
    --group_reporting > disk_results.txt
disk_end=$(date +%s)
disk_duration=$((disk_end - mem_end))

# Parse and display results
echo -e "\n=== Results ==="
echo "CPU (${cpu_duration}s):"
grep "events per second" cpu_results.txt
echo -e "\nMemory (${mem_duration}s):"
grep "MiB/sec" memory_results.txt
echo -e "\nDisk (${disk_duration}s):"
grep "IOPS" disk_results.txt
grep "BW" disk_results.txt

# Cleanup
rm test_file