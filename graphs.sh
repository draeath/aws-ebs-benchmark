#!/bin/bash

set -euo pipefail

function do_graph {
  if [[ ! -x output ]] && [[ ! -d output  ]]; then
    mkdir -v output
  fi
  fio-plot/fio_plot/fio_plot --source 'Paul Bransford <paul.bransford@epi.usf.edu>' "$@"
}

# .
# ├── xfs
# │   ├── raid0
# │   │   ├── gp2
# │   │   └── gp3
# │   └── single
# │       ├── gp2
# │       └── gp3
# └── zfs
#     ├── raid0
#     │   ├── compressed
#     │   │   ├── gp2
#     │   │   └── gp3
#     │   ├── gp2
#     │   └── gp3
#     └── single
#         ├── compressed
#         │   ├── gp2
#         │   └── gp3
#         ├── gp2
#         └── gp3

for input in xfs/{single,raid0}/gp{2,3} zfs/{single,raid0}/{,compressed/}gp{2,3}
do
  inputtitle="${input//// }"
  outputprefix="output/${input////_}"
  if [[ ! -e "${outputprefix}_latency_randread.png" ]] && [[ ! -e "${outputprefix}_latency_randread.webp" ]]
  then
    do_graph --title "Latency Performance: $inputtitle" \
        --subtitle "Random Reads" \
        --input-directory "$input" \
        --iodepth-numjobs-3d \
        -t lat -r randread \
        --filter read \
        --output "${outputprefix}_latency_randread.png"
  fi
  if [[ ! -e "${outputprefix}_latency_randwrite.png" ]] && [[ ! -e "${outputprefix}_latency_randwrite.webp" ]]
  then
    do_graph --title "Latency Performance: $inputtitle" \
        --subtitle "Random Writes" \
        --input-directory "$input" \
        --iodepth-numjobs-3d \
        -t lat -r randwrite \
        --filter write \
        --output "${outputprefix}_latency_randwrite.png"
  fi
  if [[ ! -e "${outputprefix}_iops_randread.png" ]] && [[ ! -e "${outputprefix}_iops_randread.webp" ]]
  then
    do_graph --title "IOPS Performance: $inputtitle" \
        --subtitle "Random Reads" \
        --input-directory "$input" \
        --iodepth-numjobs-3d \
        -t iops -r randread \
        --filter read \
        --output "${outputprefix}_iops_randread.png"
  fi
  if [[ ! -e "${outputprefix}_iops_randwrite.png" ]] && [[ ! -e "${outputprefix}_iops_randwrite.webp" ]]
  then
    do_graph --title "IOPS Performance: $inputtitle" \
        --subtitle "Random Writes" \
        --input-directory "$input" \
        --iodepth-numjobs-3d \
        -t iops -r randwrite \
        --filter write \
        --output "${outputprefix}_iops_randwrite.png"
  fi
done

if [ "$(find output -mindepth 1 -maxdepth 1 -type f -name "*.png" -printf '.' | wc -c)" != "0" ]
then
  if hash gm 2>/dev/null
  then
    mogrify_command="gm mogrify"
  elif hash mogrify 2>/dev/null
  then
    mogrify_command="mogrify"
  else
    echo "graphicsmagick or imagemagick not found, leaving images as-is..."
    exit 0
  fi
  ${mogrify_command} -verbose -format webp -quality 90 "output/*.png"
  find output -mindepth 1 -maxdepth 1 -type f -name "*.png" -delete
fi
