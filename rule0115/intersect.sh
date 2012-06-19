#!/bin/bash

graph=$1
names=$2

comm -12 <(grep -e label "$1" | cut -d '=' -f 2 | cut -b 2- | sort) <(cat "$2" | sort | uniq)

