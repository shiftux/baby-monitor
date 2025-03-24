#!/bin/bash
while true; do
    sed "s#replace#$(tail -n 1 /sys/bus/w1/devices/28-3c01e0760b47/w1_slave | \
        awk '{print $10}' | \
        sed 's#t=##' | \
        sed 's#.#&.#2')#" /opt/picam/subtitle_temp > hooks/subtitle
    sleep 5
done