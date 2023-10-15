#!/bin/bash

# Initializing the array for source objects
srcarr=()

# Parsing arguments
while [[ $# -gt 0 ]]
do
  key="${1}"
  case ${key} in
    "--target-directory-prefix" | "-t")
      prefix=${2}
      shift 2
      ;;
    "--help" | "-h" | "help")
      echo "Usage: ecp [OPTION]... SOURCE -t PREFIX"
      echo "PREFIX is the prefix of target directories."
      
      exit 1
      ;;
    *)
      srcarr[${#srcarr[@]}]=${1}
      shift 1
      ;;
  esac
done

dirlist=$(find $(dirname ${prefix}) -maxdepth 1 -type d -name "${prefix##*/}*" | sort)

# copying source objects to each target directory
for i in ${!srcarr[@]}
do
  for d in ${dirlist}
  do
    cp -r ${srcarr[${i}]} ${d}/
  done
done
exit
