#!/bin/bash

# Function to read CPU temperature from hwmon (first available CPU temp sensor)
get_cpu_temp() {
  temp_raw=$(cat "/sys/class/hwmon/hwmon5/temp1_input")
  echo "$((temp_raw / 1000))"
  return
  echo "null"
}

# Function to read GPU temperature using nvidia-smi (Nvidia GPUs)
get_gpu_temp() {
  if command -v nvidia-smi &>/dev/null; then
    temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
    if [[ $? -eq 0 && "$temp" != "" ]]; then
      echo "$temp"
      return
    fi
  fi
  echo "null"
}

cpu_temp=$(get_cpu_temp)
gpu_temp=$(get_gpu_temp)

# Output JSON
echo "C: $cpu_temp° G: $gpu_temp°"
