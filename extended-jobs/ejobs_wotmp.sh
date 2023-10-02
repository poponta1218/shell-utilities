#!/bin/bash

# Define functions
# Get parent process IDs (PPIDs)
get_ppids() {
  local ppid_arr=()
  # PPID of lost-PPID process is 1
  ppid_arr+=(1)
  # parent process of commands you executed is -[ba|tc|z]sh
  ppid_arr+=($(ps a -o uid,pid,ppid,cmd | grep -E "\-(ba|c|tc|z)sh" | awk -v uid="$(id -u)" '$1 == uid {print $2}'))
  echo "${ppid_arr[@]}"
}

# Get detailed information for each PPID
get_process_info() {
  local ppid="$1"
  reg="(${0}|\?|ps|awk|grep|tr|cut|\-(ba|c|tc|z)sh)"
  ps ax -o f,uid,pid,ppid,stat,cmd | awk -v f="0" -v uid="$(id -u)" -v ppid="${ppid}" '$1 == f && $2 == uid && $4 == ppid' |\
  grep -Ev "${reg}" | tr -s ' ' | cut -d ' ' -f 3,5,6-
}

# Get current working directory for a given PID
get_cwd() {
  local pid="$1"
  ls -al "/proc/${pid}/cwd" | awk '{print $11}'
}

# Format and display the process information
display_process_info() {
  local pid_info="$1"
  local stat_info="$2"
  local cmd_info="$3"
  local dir_info="$4"

  # Find the maximum width for each column
  pid_width=$(awk -F "#" 'BEGIN{max = length("PID")} {if(length($1) > max){max = length($1)}} END{print max}' <(echo "${pid_info}"))
  stat_width=$(awk -F "#" 'BEGIN{max = length("STAT")} {if(length($1) > max){max = length($1)}} END{print max}' <(echo "${stat_info}"))
  cmd_width=$(awk -F "#" 'BEGIN{max = length("COMMAND")} {if(length($1) > max){max = length($1)}} END{print max}' <(echo "${cmd_info}"))

  # Format the header and process information
  pid_out=$(awk -F "#" -v f="%${pid_width}s\n" -v t="PID" 'BEGINFILE{printf(f, t)} {printf(f, $1)}' <(echo "${pid_info}"))
  stat_out=$(awk -F "#" -v f="%${stat_width}s\n" -v t="STAT" 'BEGINFILE{printf(f, t)} {printf(f, $1)}' <(echo "${stat_info}"))
  cmd_out=$(awk -F "#" -v f="%${cmd_width}s\n" -v t="COMMAND" 'BEGINFILE{printf(f, t)} {printf(f, $1)}' <(echo "${cmd_info}"))
  dir_out=$(awk -F "#" -v f="%s\n" -v t="DIRECTORY" 'BEGINFILE{printf(f, t)} {printf(f, $1)}' <(echo "${dir_info}"))

  # Display the header and process information
  paste <(echo "${pid_out}") \
        <(echo "${stat_out}") \
        <(echo "${cmd_out}") \
        <(echo "${dir_out}")
}

# Main routine
# Get parent process IDs
ppid_arr=($(get_ppids))

# Get process information for each PPID
info=""
for ppid in "${ppid_arr[@]}"
do
  add_info=$(get_process_info "${ppid}")
  if [ "${add_info}" != "" ]; then
    info+="${add_info}"$'\n'
  fi
done

# Split the process information into separate variables
pid_info=$(echo "${info}" | cut -d ' ' -f 1)
stat_info=$(echo "${info}" | cut -d ' ' -f 2 | sed -i -e '/R/c RUN' -e '/S/c RUN' -e '/D/c RUN' -e '/T/c SUS' -e '/Z/c ZOMBIE')
cmd_info=$(echo "${info}" | cut -d ' ' -f 3-)
dir_info=""

# Process each PID to get the current working directory
while IFS= read -r pid
do
  dir_info+=$(get_cwd "${pid}")$'\n'
done < <(echo "${pid_info}")

# Format and display the process information
display_process_info "${pid_info}" "${stat_info}" "${cmd_info}" "${dir_info}"

exit
