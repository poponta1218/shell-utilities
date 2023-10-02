#!/bin/bash

# Parsing arguments
while [[ $# -gt 0 ]]
do
  key="${1}"
  case ${key} in
    "--parent" | "-p")
      parent=${2}
      shift 2
      ;;
    "--sub" | "-s")
      sub=${2}
      shift 2
      ;;
    #" --type" | "-t")
    #   obj_type=$2
    #   shift 2
    #   ;;
    "--prefix" | "-f")
      prefix=${2}
      shift 2
      ;;
    "--help" | "-h" | "help")
      # echo "Usage: $0 (--type T:default=d) [--parent P | --sub S]"
      echo "Usage: ${0} [--parent P | --sub S] [--prefix PREFIX]"
      # echo "T is the type of objects you want to distribute."
      # echo "You can input f or d"
      echo "P is the number of parent directories."
      echo "S is the number of sub objects."
      echo "PREFIX is the non-sequential part of the object you want to distribute."
      # echo "Also you can use -t, -p or -s instead of --type, --parent or --sub"
      echo "Also you can use -p, -s and -f instead of --parent, --sub and --prefix."
      
      exit 1
      ;;
    *)
      echo "Invalid argument: ${1}"
      exit 1
      ;;
  esac
done

# if [[ ${obj_type} -ne f -o ${obj_type} -nq d ]] ; then
#   echo ""
#   exit 1
# fi

if [ -z "${parent}" ] && [ -z "${sub}" ] ; then
  echo "Either parent or sub must be specified."
  exit 1
fi

if [ ! -z "${parent}" ] && [ ! -z "${sub}" ] ; then
  echo "Either parent or sub can be specified, but not both."
  exit 1
fi

# Counting directories with prefix
# num_obj=$(find $(pwd) -maxdepth 1 -type ${obj_type} -name "${prefix}*" | wc -l)
num_obj=$(find $(pwd) -maxdepth 1 -name "${prefix}*" | wc -l)

# Calculating P and S
if [ ! -z "${parent}" ] ; then
  P=${parent}
  S=$(( num_obj / P ))
else
  S=${sub}
  P=$(( num_obj / S ))
fi

# Calculating R
R=$(( num_obj % P ))

# Making parentdir and Moving subobj to parentdir
i=0
j=0
k=1
for d in ${prefix}*
do
  if [[ ${d} == ${prefix}_* ]] ; then
    continue
  fi
  ((i++))
  if [[ $(( i % (S + 1) )) -eq 0 ]] ; then
    ((k++))
  fi
  if [[ ${k} -le ${R} ]] ; then
    target=$(( (i - 1) / (S + 1) + 1 ))
  else
    ((j++))
    target=$(( R + (j - 1) / S + 1 ))
  fi

  if [ ! -d ${prefix}_tmp_${target} ] ; then
    mkdir ${prefix}_tmp_${target}
  fi
  mv ${d} ${prefix}_tmp_${target}/
done

# Rename parentdir
for d in ${prefix}_tmp_*
do
  start_obj=$(find ${d} -maxdepth 1 -name "${prefix}*" | sort | head -n 2 | tail -n 1)
  end_obj=$(find ${d} -maxdepth 1 -name "${prefix}*" | sort | tail -n 1)
  rename_dir=${prefix}_${start_obj##*${prefix}}_${end_obj##*${prefix}}
  mv ${d} ${rename_dir}
done

echo "Done."
exit
