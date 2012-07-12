#!/bin/bash

while file=$(inotifywait -e modify -e create --format '%w/%f' .)
do
    ldv-upload "$file" &
done

