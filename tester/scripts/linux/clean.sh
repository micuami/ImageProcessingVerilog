#!/bin/bash

if [ "$1" == "ref" ]; then
    rm -rf ../../scripts/../build/lib/work
    rm -rf ../../scripts/../build/lib/tester
    rm -rf ../../scripts/../build/lib/tests
    rm -rf ../../scripts/../build/lib/reference
elif [ "$1" == "noref" ]; then
    rm -rf ../../scripts/../build/lib/work
    rm -rf ../../scripts/../build/lib/tester
    rm -rf ../../scripts/../build/lib/tests
    rm -rf ../../scripts/../build/lib/uut
    rm -rf ../../scripts/../build/bin
else
    rm -rf ../../scripts/../build
fi

rm -rf ../../scripts/../run
