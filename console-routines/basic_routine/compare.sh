#!/bin/bash

if diff out-comm-1.txt that.txt > /dev/null
then
    echo "No difference"
else
    echo "Differences:"
    sdiff out-comm-1.txt that.txt
fi

