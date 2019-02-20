#!/bin/bash
# This little script is just for demonstrating the different steps 

echo ${BASH_SOURCE[0]}
echo "$(dirname "${BASH_SOURCE[0]}")"
echo "cd task: $( cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1)"
echo "PWD: $(pwd)"
DIR="$( cd "$(dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)"
echo "DIR: $DIR"