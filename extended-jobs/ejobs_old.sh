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
  local pid_in="$1"
  local stat_in="$2"
  local cmd_in="$3"
  local dir_in="$4"

  local pid_out="pid2.pid"
  local stat_out="stat2.pid"
  local cmd_out="cmd2.pid"
  local dir_out="dir2.pid"

  # Find the maximum width for each column
  pid_width=$(awk -F "#" 'BEGIN{max = length("PID")} {if(length($1) > max){max = length($1)}} END{print max}' "${pid_in}")
  stat_width=$(awk -F "#" 'BEGIN{max = length("STAT")} {if(length($1) > max){max = length($1)}} END{print max}' "${stat_in}")
  cmd_width=$(awk -F "#" 'BEGIN{max = length("COMMAND")} {if(length($1) > max){max = length($1)}} END{print max}' "${cmd_in}")

  # Format the header and process information
  awk -F "#" -v f="%${pid_width}s\n" -v t="PID" \
  'BEGIN{printf(f, t)} {printf(f, $1)}' "${pid_in}" > "${tmp_dir}/${pid_out}"
  awk -F "#" -v f="%${stat_width}s\n" -v t="STAT" \
  'BEGIN{printf(f, t)} {printf(f, $1)}' "${stat_in}" > "${tmp_dir}/${stat_out}"
  awk -F "#" -v f="%${cmd_width}s\n" -v t="COMMAND" \
  'BEGIN{printf(f, t)} {printf(f, $1)}' "${cmd_in}" > "${tmp_dir}/${cmd_out}"
  awk -F "#" -v f="%s\n" -v t="DIRECTORY" \
  'BEGIN{printf(f, t)} {printf(f, $1)}' "${dir_in}" > "${tmp_dir}/${dir_out}"

  # Display the header and process information
  paste "${tmp_dir}/${pid_out}" "${tmp_dir}/${stat_out}" "${tmp_dir}/${cmd_out}" "${tmp_dir}/${dir_out}"
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
sed -i -e '/R/c RUN' -e '/S/c RUN' -e '/D/c RUN' -e '/T/c SUS' -e '/Z/c ZOMBIE' "${tmp_dir}/stat.pid"
cut -d ' ' -f 3- "${tmp_dir}/tmp.pid" > "${tmp_dir}/cmd.pid"
while read -r pid
do
  get_cwd "${pid}"
done < "${tmp_dir}/pid.pid" > "${tmp_dir}/dir.pid"

# Format and display the process information
display_process_info "${tmp_dir}/pid.pid" "${tmp_dir}/stat.pid" "${tmp_dir}/cmd.pid" "${tmp_dir}/dir.pid"

exit
