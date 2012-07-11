#!/bin/bash

while file=$(inotifywait -e modify -e create --format '%w/%f' .)
do
   cp "$file" /home/work/documents/Dropbox/ldv/
done

