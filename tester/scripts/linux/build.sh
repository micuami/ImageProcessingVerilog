#!/bin/bash

nodup=

if [ "$1" == "nodup" ]; then
     nodup="nodup"
fi

./build_base.sh $nodup

for d in ../../tests/*; do
     ./build_test.sh `basename $d` nobase
done
