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
  reg="(${0}|\?|ps|awk|grep|tr|cut|ssh-add|\-(ba|c|tc|z)sh)"
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
  local pid_file="$1"
  local stat_file="$2"
  local cmd_file="$3"
  local dir_file="$4"

  # Find the maximum width for each column
  pid_width=$(awk -F "#" 'BEGIN{max = length("PID")} {if(length($1) > max){max = length($1)}} END{print max}' "${pid_file}")
  stat_width=$(awk -F "#" 'BEGIN{max = length("STAT")} {if(length($1) > max){max = length($1)}} END{print max}' "${stat_file}")
  cmd_width=$(awk -F "#" 'BEGIN{max = length("COMMAND")} {if(length($1) > max){max = length($1)}} END{print max}' "${cmd_file}")

  # Format the header and process information
  awk -i inplace -F "#" -v f="%${pid_width}s\n" -v t="PID" \
  'BEGINFILE{printf(f, t)} {printf(f, $1)}' "${pid_file}"
  awk -i inplace -F "#" -v f="%${stat_width}s\n" -v t="STAT" \
  'BEGINFILE{printf(f, t)} {printf(f, $1)}' "${stat_file}"
  awk -i inplace -F "#" -v f="%${cmd_width}s\n" -v t="COMMAND" \
  'BEGINFILE{printf(f, t)} {printf(f, $1)}' "${cmd_file}"
  awk -i inplace -F "#" -v f="%s\n" -v t="DIRECTORY" \
  'BEGINFILE{printf(f, t)} {printf(f, $1)}' "${dir_file}"

  # Display the header and process information
  paste "${pid_file}" "${stat_file}" "${cmd_file}" "${dir_file}"
}

# Cleanup temporary files
cleanup() {
  rm -f "${tmp_dir}"/*.pid
}


# Main routine
# Initialize
tmp_dir=$(mktemp -d)
trap cleanup EXIT

# Get parent process IDs
ppid_arr=($(get_ppids))

# Get process information for each PPID
for ppid in "${ppid_arr[@]}"
do
  get_process_info "${ppid}" >> "${tmp_dir}/tmp.pid"
done

# Split the process information into separate files
cut -d ' ' -f 1 "${tmp_dir}/tmp.pid" > "${tmp_dir}/pid.pid"
cut -d ' ' -f 2 "${tmp_dir}/tmp.pid" > "${tmp_dir}/stat.pid"
sed -i -e '/R/c RUN' -e '/S/c RUN' -e '/D/c RUN' -e '/T/c SUS' -e '/Z/c DEFUNCT' "${tmp_dir}/stat.pid"
cut -d ' ' -f 3- "${tmp_dir}/tmp.pid" > "${tmp_dir}/cmd.pid"
while read -r pid
do
  get_cwd "${pid}"
done < "${tmp_dir}/pid.pid" > "${tmp_dir}/dir.pid"

# Format and display the process information
display_process_info "${tmp_dir}/pid.pid" "${tmp_dir}/stat.pid" "${tmp_dir}/cmd.pid" "${tmp_dir}/dir.pid"

exit
