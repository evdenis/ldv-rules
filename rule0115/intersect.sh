#!/bin/bash

graph=$1
names=$2

comm -12 <(grep -e label "$graph" | cut -d '=' -f 2 | cut -b 2- | sort -u) <(sort -u "$names")

