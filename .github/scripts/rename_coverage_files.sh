#!/usr/bin/bash
for f in result/*; do 
    if [[ $f == *ras2* || $f == *ratweb2* ]]; then
        mv "$f" "$f.xml"; 
    else
        mv "$f" "$f.lcov"; 
    fi
done
