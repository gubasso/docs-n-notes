#!/bin/bash

log_file="my-program.log"
pid_file="my-program.pid"


# --- Self-detachment block ---
if [[ -z "$RUNNING_DETACHED" ]]; then
  export RUNNING_DETACHED=1
  nohup "$0" "$@" > /dev/null 2>&1 &
  echo "$!" > "$pid_file"
  echo "Script started in background with PID $(cat "$pid_file"). Check $log_file for output."
  exit 0
fi

# --- Execution block (runs in the background) ---
# Set a trap to remove the PID file when the process exits (normally or via signals)
trap 'rm -f "$pid_file"' EXIT

# Capture start time
start_time=$(date)
start_epoch=$(date +%s)
echo "Script started at: $start_time" > "$log_file"

# Create a file to indicate the process is running
touch script.running
trap 'rm -f script.running' EXIT

# Run the Python script, appending its output to $log_file
python my_program.py some_cli_arg --some-opt >> "$log_file" 2>&1

# Remove the running indicator file after the Python script finishes
rm script.running

# Capture end time and calculate total runtime
end_time=$(date)
end_epoch=$(date +%s)
runtime=$((end_epoch - start_epoch))

# Convert runtime (in seconds) to hh:mm:ss
hours=$(( runtime / 3600 ))
minutes=$(( (runtime % 3600) / 60 ))
seconds=$(( runtime % 60 ))

# Format the runtime as hh:mm:ss (with zero padding)
formatted_runtime=$(printf "%02d:%02d:%02d" $hours $minutes $seconds)

echo "Script ended at: $end_time" >> "$log_file"
echo "Total runtime: $formatted_runtime (hh:mm:ss)" >> "$log_file"
